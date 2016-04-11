package de.mfo.surfer.control;

import de.mfo.jsurf.rendering.*;
import de.mfo.jsurf.rendering.cpu.*;
import de.mfo.jsurf.util.RotateSphericalDragger;
import de.mfo.jsurf.util.BasicIO;
import static de.mfo.jsurf.rendering.cpu.CPUAlgebraicSurfaceRenderer.AntiAliasingMode;
import de.mfo.jsurf.parser.*;
import java.net.URL;
import java.util.*;
import java.io.*;
import javax.vecmath.*;

import de.mfo.surfer.Main;
import java.nio.IntBuffer;
import java.util.concurrent.Executors;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.Semaphore;
import java.util.concurrent.TimeUnit;
import java.util.function.Function;
import javafx.application.Platform;
import javafx.beans.binding.Bindings;
import javafx.beans.binding.BooleanBinding;
import javafx.beans.property.BooleanProperty;
import javafx.beans.property.DoubleProperty;
import javafx.beans.property.IntegerProperty;
import javafx.beans.property.ObjectProperty;
import javafx.beans.property.ReadOnlyBooleanProperty;
import javafx.beans.property.ReadOnlyBooleanWrapper;
import javafx.beans.property.ReadOnlyStringProperty;
import javafx.beans.property.ReadOnlyStringWrapper;
import javafx.beans.property.ReadOnlyObjectWrapper;
import javafx.beans.property.ReadOnlyObjectProperty;
import javafx.beans.property.SimpleBooleanProperty;
import javafx.beans.property.SimpleDoubleProperty;
import javafx.beans.property.SimpleIntegerProperty;
import javafx.beans.property.SimpleObjectProperty;
import javafx.beans.property.SimpleStringProperty;
import javafx.beans.property.StringProperty;
import javafx.beans.value.ChangeListener;
import javafx.concurrent.Task;
import javafx.geometry.Bounds;
import javafx.scene.canvas.Canvas;
import javafx.scene.canvas.GraphicsContext;
import javafx.scene.effect.DropShadow;
import javafx.scene.image.Image;
import javafx.scene.image.PixelFormat;
import javafx.scene.image.PixelWriter;
import javafx.scene.layout.Region;
import javafx.scene.Node;
import javafx.scene.paint.Color;
import javafx.scene.transform.Scale;
import javafx.scene.transform.Translate;
import java.util.Map;
import javafx.beans.property.MapProperty;
import javafx.beans.property.SimpleMapProperty;
import javafx.collections.ObservableMap;
import javafx.collections.MapChangeListener;
import javafx.collections.FXCollections;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class RenderArea extends Region
{
    private static final Logger logger = LoggerFactory.getLogger( RenderArea.class );

    Canvas canvas;
    SimpleBooleanProperty triggerRepaintOnChange;

    SimpleStringProperty formula;

    ReadOnlyBooleanWrapper isValid;
    BooleanBinding hasNullValues;
    SimpleBooleanProperty isFormulaValid;
    ReadOnlyObjectWrapper< Throwable > error;
    ReadOnlyStringWrapper errorMessage;

    SimpleMapProperty< String, Double > parameters;

    SimpleObjectProperty< Color > frontColor;
    SimpleObjectProperty< Color > backColor;

    CPUAlgebraicSurfaceRendererExt asr;

    SimpleIntegerProperty renderSize;

    RotateSphericalDragger rsd;

    public RenderArea()
    {
        setPickOnBounds( false );

        canvas = new Canvas();
        getChildren().add( canvas );

        asr = new CPUAlgebraicSurfaceRendererExt();

        triggerRepaintOnChange = new SimpleBooleanProperty( true );

        formula = new SimpleStringProperty();
        isValid = new ReadOnlyBooleanWrapper();
        error = new ReadOnlyObjectWrapper< Throwable >();
        errorMessage = new ReadOnlyStringWrapper();
        errorMessage.bind(
            Bindings.createStringBinding(
                () ->
                {
                    if( getError() == null )
                    {
                        return "";
                    }
                    else
                    {
                        StringWriter sw = new StringWriter();
                        getError().printStackTrace( new PrintWriter( sw ) );
                        return sw.toString();
                    }
                },
                error
            )
        );

        parameters = new SimpleMapProperty< String, Double >( FXCollections.< String, Double >observableHashMap() );

        frontColor = new SimpleObjectProperty< Color >();
        backColor = new SimpleObjectProperty< Color >();

        renderSize = new SimpleIntegerProperty( 1 );

        hasNullValues = Bindings.isNull( formula );
        hasNullValues = hasNullValues.or( Bindings.isNull( frontColor ) );
        hasNullValues = hasNullValues.or( Bindings.isNull( backColor ) );

        isFormulaValid = new SimpleBooleanProperty();

        isValid.bind( hasNullValues.not().and( isFormulaValid ) );

        ChangeListener cl = ( observable, oldValue, newValue ) -> Platform.runLater( () -> triggerRepaint() );

        formula.addListener( cl );

        parameters.addListener(
            new MapChangeListener< String, Double >()
            {
                List< String > names = Arrays.asList( new String[]{ "a", "b", "c", "d", "scale_factor" } );

                @Override
                public void onChanged( Change<? extends String,? extends Double> change )
                {
                    names.forEach( n -> { if( change.wasAdded() && change.getKey().equals( n ) ) {
                        asr.setParameterValue( n, change.getValueAdded() );
                    } } );
                    Platform.runLater( () -> triggerRepaint() );
                }
            }
        );

        Function< Color, Color3f > c2c3f = c -> new Color3f( ( float ) c.getRed(), ( float ) c.getGreen(), ( float ) c.getBlue() );
        frontColor.addListener( ( p1, p2, newValue ) -> { asr.getFrontMaterial().setColor( c2c3f.apply( newValue ) ); triggerRepaint(); } );
        backColor.addListener( ( p1, p2, newValue ) -> { asr.getBackMaterial().setColor( c2c3f.apply( newValue ) ); triggerRepaint(); } );

        this.sceneProperty().addListener( cl );

        Node renderAreaPlaceholder = Main.< Node >fxmlLookup( "#Surfer_Rendering" );
        //renderAreaPlaceholder.setVisible( false );
        Bounds renderAreaBB = renderAreaPlaceholder.getBoundsInParent();
        this.relocate( renderAreaBB.getMinX(), renderAreaBB.getMinY() );
        this.canvas.widthProperty().bind( renderSize );
        this.canvas.heightProperty().bind( renderSize );

        renderAreaPlaceholder.localToSceneTransformProperty().addListener( cl );

        Scale scale = new Scale( 1.0, 1.0, 0.0, 0.0 );
        scale.xProperty().bind( Bindings.divide( renderAreaBB.getWidth(), renderSize ) );
        scale.yProperty().bind( Bindings.divide( renderAreaBB.getHeight(), renderSize ).negate() );
        Translate translate = new Translate();
        translate.yProperty().bind( renderSize.negate() );

        this.canvas.getTransforms().addAll( scale, translate );

        rsd = new RotateSphericalDragger();
        setOnMousePressed( e -> rsd.startDrag( new java.awt.Point( ( int ) e.getX(), ( int ) e.getY() ) ) );
        setOnMouseDragged( e -> { rsd.dragTo( new java.awt.Point( ( int ) e.getX(), ( int ) e.getY() ) ); triggerRepaint(); } );

        try
        {
            loadFromFile( Main.class.getResource( "gallery/default.jsurf" ) );
        }
        catch( Exception e )
        {
            e.printStackTrace();
        }
    }

    RenderingTask taskLowQuality;
    RenderingTask taskMediumQuality;
    RenderingTask taskHighQuality;
    RenderingTask taskUltraQuality;
    double secondsPerPixel = 0.0001;
    double targetFps = 30.0;
    int minRenderSize = 100;

    ExecutorService executor = Executors.newSingleThreadExecutor( r -> { Thread t = new Thread( r ); t.setDaemon( true ); return t; } );
    void triggerRepaint()
    {
        if( this.getScene() != null && this.getParent() != null && isValid.get() && triggerRepaintOnChange.get() )
        {
            if( taskLowQuality != null && !taskLowQuality.isRunning() )
                taskLowQuality.cancel();
            if( taskMediumQuality != null )
                taskMediumQuality.cancel();
            if( taskHighQuality != null )
                taskHighQuality.cancel();
            if( taskUltraQuality != null )
                taskUltraQuality.cancel();

            // set up rendering environemnt
            passDataToASR();

            // calculate upper bound of the resolution
            Bounds b = this.localToScene( this.getBoundsInLocal(), true );
            int maxSize = (int) Math.round( Math.max( b.getWidth(), b.getHeight() ) );
            int lowResSize = ( int ) Math.max( Math.min( maxSize, Math.sqrt( 1.0 / ( targetFps * secondsPerPixel ) ) ), 100 );

            taskUltraQuality = new RenderingTask(
                asr,
                this.canvas.getGraphicsContext2D(),
                maxSize,
                renderSize,
                AntiAliasingMode.SUPERSAMPLING,
                AntiAliasingPattern.OG_4x4
            );

            taskHighQuality = new RenderingTask(
                asr,
                this.canvas.getGraphicsContext2D(),
                maxSize,
                renderSize,
                AntiAliasingMode.ADAPTIVE_SUPERSAMPLING,
                AntiAliasingPattern.OG_4x4
            );
            taskHighQuality.setOnSucceeded( e -> executor.submit( taskUltraQuality ) );

            if( lowResSize < maxSize / 2 )
            {
                // add rendering step with intermediate resolution
                taskMediumQuality = new RenderingTask(
                    asr,
                    this.canvas.getGraphicsContext2D(),
                    ( maxSize + lowResSize ) / 2,
                    renderSize,
                    AntiAliasingMode.ADAPTIVE_SUPERSAMPLING,
                    AntiAliasingPattern.QUINCUNX
                );
            }
            else
            {
                // add dummy rendering task, that does nothing
                taskMediumQuality = new RenderingTask(
                    asr,
                    this.canvas.getGraphicsContext2D(),
                    ( maxSize + lowResSize ) / 2,
                    renderSize,
                    AntiAliasingMode.ADAPTIVE_SUPERSAMPLING,
                    AntiAliasingPattern.QUINCUNX
                )
                {
                    @Override protected void scheduled() {}
                    @Override public Double call() { return secondsPerPixel; }
                    @Override protected void succeeded() {}
                };
            }
            taskMediumQuality.setOnSucceeded( e -> executor.submit( taskHighQuality ) );

            taskLowQuality = new RenderingTask(
                asr,
                this.canvas.getGraphicsContext2D(),
                lowResSize,
                renderSize,
                AntiAliasingMode.ADAPTIVE_SUPERSAMPLING,
                AntiAliasingPattern.QUINCUNX
            );
            taskLowQuality.setOnSucceeded( e ->
                {
                    secondsPerPixel = ( double ) e.getSource().getValue();
                    executor.submit( taskMediumQuality );
                }
            );

            executor.submit( taskLowQuality );
        }
    }

    protected static void setOptimalCameraDistance( Camera c )
    {
        float cameraDistance;
        switch( c.getCameraType() )
        {
            case ORTHOGRAPHIC_CAMERA:
                cameraDistance = 1.0f;
                break;
            case PERSPECTIVE_CAMERA:
                cameraDistance = ( float ) ( 1.0 / Math.sin( ( Math.PI / 180.0 ) * ( c.getFoVY() / 2.0 ) ) );
                break;
            default:
                throw new RuntimeException();
        }
        c.lookAt( new Point3d( 0, 0, cameraDistance ), new Point3d( 0, 0, -1 ), new Vector3d( 0, 1, 0 ) );
    }

    void passDataToASR()
    {
        try
        {
            if( !formula.getValue().equals( asr.getSurfaceFamilyString() ) )
                asr.setSurfaceFamily( formula.getValue() );

            asr.setTransform( rsd.getRotation() );
            double scaleFactor = parameters.get( "scale_factor" );
            asr.setSurfaceTransform( new Matrix4d(
                Math.pow( 10, scaleFactor), 0.0, 0.0, 0.0,
                0.0, Math.pow( 10, scaleFactor), 0.0, 0.0,
                0.0, 0.0, Math.pow( 10, scaleFactor), 0.0,
                0.0, 0.0, 0.0, 1.0
            ) );
            setOptimalCameraDistance( asr.getCamera() );

            List< String > names = Arrays.asList( new String[]{ "a", "b", "c", "d" } );
            names.forEach( n -> { if( parameters.containsKey( n ) ) asr.setParameterValue( n, parameters.get( n ) ); } );

            Function< Color, Color3f > c2c3f = c -> new Color3f( ( float ) c.getRed(), ( float ) c.getGreen(), ( float ) c.getBlue() );

            asr.getFrontMaterial().setColor( c2c3f.apply( frontColor.getValue() ) );
            asr.getBackMaterial().setColor( c2c3f.apply( backColor.getValue() ) );
        }
        catch( Exception e )
        {

            error.setValue( e );
            isFormulaValid.set( false );
        }
    }

    void retriveDataFromASR()
    {
        triggerRepaintOnChange.setValue( false );
        formula.setValue( asr.getSurfaceFamilyString() );

        asr.getAssignedParameters().forEach( e -> parameters.put( e.getKey(), e.getValue() ) );

        Function< Color3f, Color > c3f2c = c -> new Color( c.x, c.y, c.z, 1.0 );

        frontColor.setValue( c3f2c.apply( asr.getFrontMaterial().getColor() ) );
        backColor.setValue( c3f2c.apply( asr.getBackMaterial().getColor() ) );

        triggerRepaintOnChange.setValue( true );
        triggerRepaint();
    }

    public void loadFromString( String s )
    {
        try
        {
            Properties props = new Properties();
            props.load( new ByteArrayInputStream( s.getBytes() ) );
            loadFromProperties( props );
        }
        catch( IOException ioe )
        {
            throw new RuntimeException( ioe );
        }
    }

    public void loadFromFile( URL url )
        throws IOException
    {
        Properties props = new Properties();
        props.load( url.openStream() );
        loadFromProperties( props );
    }

    public void loadFromProperties( Properties props )
    {
        isFormulaValid.setValue( true );
        triggerRepaintOnChange.setValue( false );
        try
        {
            asr.setSurfaceFamily( props.getProperty( "surface_equation" ) );

            Set< Map.Entry< Object, Object > > entries = props.entrySet();
            String parameter_prefix = "surface_parameter_";
            for( Map.Entry< Object, Object > entry : entries )
            {
                String name = (String) entry.getKey();
                if( name.startsWith( parameter_prefix ) )
                {
                    String parameterName = name.substring( parameter_prefix.length() );
                    float parameterValue = Float.parseFloat( ( String ) entry.getValue() );
                    asr.setParameterValue( parameterName, parameterValue );
                }
            }

            asr.getCamera().loadProperties( props, "camera_", "" );

            asr.getFrontMaterial().loadProperties(props, "front_material_", "");
            asr.getBackMaterial().loadProperties(props, "back_material_", "");

            for( int i = 0; i < asr.MAX_LIGHTS; i++ )
            {
                asr.getLightSource( i ).setStatus(LightSource.Status.OFF);
                asr.getLightSource( i ).loadProperties( props, "light_", "_" + i );
            }
            Function< String, Color3f > string2color = s ->
            {
                Scanner sc = new Scanner( s );
                sc.useLocale( Locale.US );
                return new Color3f( sc.nextFloat(), sc.nextFloat(), sc.nextFloat() );
            };

            asr.setBackgroundColor( string2color.apply( props.getProperty( "background_color" ) ) );
            parameters.put( "scale_factor", Double.parseDouble( props.getProperty( "scale_factor" ) ) );
            rsd.setRotation( BasicIO.fromMatrix4dString( props.getProperty( "rotation_matrix" ) ) );

            retriveDataFromASR();
        }
        catch( Exception e )
        {
            error.setValue( e );
            isFormulaValid.set( false );
        }
        triggerRepaintOnChange.setValue( true );
        triggerRepaint();
    }

    // triggerRepaintOnChange
    public boolean getTriggerRepaintOnChange()
    {
        return triggerRepaintOnChange.getValue();
    }

    public void setTriggerRepaintOnChange( boolean value )
    {
        triggerRepaintOnChange.setValue( value );
    }

    public BooleanProperty triggerRepaintOnChangeProperty()
    {
        return triggerRepaintOnChange;
    }

    // formula
    public String getFormula()
    {
        return formula.getValue();
    }

    public void setFormula( String value )
    {
        formula.setValue( value );
    }

    public StringProperty formulaProperty()
    {
        return formula;
    }

    // isValid
    public boolean getIsValid()
    {
        return isValid.getValue();
    }

    public ReadOnlyBooleanProperty isValidProperty()
    {
        return isValid.getReadOnlyProperty();
    }

    // error
    public String getErrorMessage()
    {
        return errorMessage.getValue();
    }

    public ReadOnlyStringProperty errorMessageProperty()
    {
        return errorMessage.getReadOnlyProperty();
    }

    // errorMessage
    public Throwable getError()
    {
        return error.getValue();
    }

    public ReadOnlyObjectProperty< Throwable > errorProperty()
    {
        return error.getReadOnlyProperty();
    }

    // parameters
    public ObservableMap< String, Double > getParameters()
    {
        return parameters.get();
    }

    public void setParameters( ObservableMap< String, Double > value )
    {
        parameters.set( value );
    }

    public MapProperty< String, Double > parametersProperty()
    {
        return parameters;
    }

    // frontColor
    public Color getFrontColor()
    {
        return frontColor.getValue();
    }

    public void setFrontColor( Color value )
    {
        frontColor.setValue( value );
    }

    public ObjectProperty< Color > frontColorProperty()
    {
        return frontColor;
    }

    // backColor
    public Color getbackColor()
    {
        return backColor.getValue();
    }

    public void setBackColor( Color value )
    {
        backColor.setValue( value );
    }

    public ObjectProperty< Color > backColorProperty()
    {
        return backColor;
    }
}

class RenderingTask extends Task< Double >
{
    protected CPUAlgebraicSurfaceRendererExt asr;
    protected CPUAlgebraicSurfaceRendererExt.DrawcallStaticDataExt dcsd;
    protected GraphicsContext graphicsContext;
    protected int renderSize;
    protected IntegerProperty renderSizeProperty;
    protected AntiAliasingMode aam;
    protected AntiAliasingPattern aap;

    protected Semaphore semaphore;


    public RenderingTask(
        CPUAlgebraicSurfaceRendererExt asr,
        GraphicsContext graphicsContext,
        int renderSize,
        IntegerProperty renderSizeProperty,
        AntiAliasingMode aam,
        AntiAliasingPattern aap
    )
    {
        this.asr = asr;
        this.graphicsContext = graphicsContext;
        this.renderSize = renderSize;
        this.renderSizeProperty = renderSizeProperty;
        this.aam = aam;
        this.aap = aap;

        semaphore = new Semaphore( 0 );
    }

    // automatically called on the JavaFX application thread
    @Override
    protected void scheduled()
    {
        super.scheduled();

        // apply anti-aliasing settings
        asr.setAntiAliasingMode( aam );
        asr.setAntiAliasingPattern( aap );

        // grab the current state of the asr
        // (to be used later on the worker thread)
        dcsd = asr.collectDrawCallStaticDataExt(
            new int[ renderSize * renderSize ],
            renderSize,
            renderSize
        );

        // permit execution of call() method on background thread
        semaphore.release();
    }

    @Override
    protected Double call() throws Exception {
        // wait until dcsd is initialized on JavaFX application thread
        semaphore.acquire();
        long t_start = System.nanoTime();
        asr.draw( dcsd );
        long t_end = System.nanoTime();

        // return time per pixel
        return ( ( t_end - t_start ) / 1000000000.0 ) / ( renderSize * renderSize );
    }

    // automatically called on the JavaFX application thread
    @Override
    protected void succeeded()
    {
        super.succeeded();

        renderSizeProperty.setValue( Math.max( dcsd.getWidth(), dcsd.getHeight() ) );
        graphicsContext.clearRect( 0, 0, dcsd.getWidth() + 1, dcsd.getHeight() + 1 );

        graphicsContext.getPixelWriter().setPixels(
            0, 0, dcsd.getWidth(), dcsd.getHeight(),
            PixelFormat.getIntArgbInstance(),
            dcsd.getColorBuffer(), 0, dcsd.getWidth()
        );
    }
};