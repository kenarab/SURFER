package de.mfo.jsurfer.gui;

import de.mfo.jsurfer.gui.FXSurferPanel;
import javafx.scene.CustomNode;
import javafx.scene.Group;
import javafx.scene.Node;
import javafx.scene.transform.Transform;
import javafx.fxd.FXDNode;
import javafx.scene.input.MouseEvent;
import javafx.geometry.Bounds;
import javax.vecmath.*;
import java.lang.System;
//import javafx.ext.swing.SwingTextField;
import javafx.scene.layout.LayoutInfo;
import javafx.scene.layout.HBox;
//import javafx.scene.text.Font;
import javafx.ext.swing.*;
import javax.swing.JTextField;
import java.awt.Font;
import javafx.scene.input.MouseButton;
import javax.swing.event.*;
import java.util.*;
import javax.swing.event.*;
import javax.swing.*;
import javax.swing.BorderFactory;
import java.io.File;
import java.io.InputStream;
import javafx.fxd.Duplicator;
import javafx.animation.Timeline;
import javafx.animation.KeyFrame;
/**
 * @author Panda
 */

public class AlgebraicExpressionButtonPanel extends CustomNode {



    var language:java.util.Locale=java.util.Locale.GERMAN;
    def fxdButtons:FXDNode = FXDNode
	{
                url:    "{__DIR__}surfer_touchscreen_1920_x_1080.fxz"
		backgroundLoading: false;
	}
    var sliders:FXSliders= FXSliders {
        surferPanel: bind surferPanel;
        fxdButtons: fxdButtons;
        getScale: getScale,
        sceneWidth: bind width;
        sceneHeight:bind height;
        scene:scene
    }
    def loadURL:function(url:java.net.URL):Void=function(url:java.net.URL)
    {
        
        try
        {
            surferPanel.renderer.loadFromFile( url);
            surferPanel.renderer.repaintImage();

            try{surferPanel.a=surferPanel.renderer.getAlgebraicSurfaceRenderer().getParameterValue("a");}catch(e: java.lang.Exception  ){}
            try{surferPanel.b=surferPanel.renderer.getAlgebraicSurfaceRenderer().getParameterValue("b");}catch(e: java.lang.Exception  ){}
            try{surferPanel.c=surferPanel.renderer.getAlgebraicSurfaceRenderer().getParameterValue("c");}catch(e: java.lang.Exception  ){}
            try{surferPanel.d=surferPanel.renderer.getAlgebraicSurfaceRenderer().getParameterValue("d");}catch(e: java.lang.Exception  ){}

            //surferPanel.b=surferPanel.renderer.getAlgebraicSurfaceRenderer().getParameterValue("b");
            //surferPanel.c=surferPanel.renderer.getAlgebraicSurfaceRenderer().getParameterValue("c");
            //surferPanel.d=surferPanel.renderer.getAlgebraicSurfaceRenderer().getParameterValue("d");
            def FrontColor:javax.vecmath.Color3f=surferPanel.renderer.getAlgebraicSurfaceRenderer().getFrontMaterial().getColor();
            def BackColor :javax.vecmath.Color3f=surferPanel.renderer.getAlgebraicSurfaceRenderer().getBackMaterial() .getColor();
            //System.out.println("FrontColor{FrontColor.x},{FrontColor.y},{FrontColor.z}");
            //System.out.println("BackColor{BackColor.x},{BackColor.y},{BackColor.z}");
            tabField.frontColor.setColor(FrontColor);
            tabField.backColor.setColor(BackColor);
            //renderer.getAlgebraicSurfaceRenderer().setParameterValue("a", a);
            //surferPanel.a=surferPanel.renderer.getAlgebraicSurfaceRenderer().getParameterValue("a");
            //System.out.println("loaded Par a:{surferPanel.renderer.getAlgebraicSurfaceRenderer().getParameterValue("a")}");
            //surferPanel.b=surferPanel.renderer.getAlgebraicSurfaceRenderer().getParameterValue("b");
            test.setText(surferPanel.renderer.getAlgebraicSurfaceRenderer().getSurfaceFamilyString());
        }
        catch(e: java.lang.Exception  )
        {
            var  message:String= "Could not open file \" {url.getPath()  } \".";
            if( e.getMessage() != null )
            message = "{message}\n\nMessage: {e.getMessage()}";
            JOptionPane.showMessageDialog( null, message, "Error", JOptionPane.OK_OPTION );
        }
    }
    var tabField:TabField = TabField
    {
        language:bind language//java.util.Locale.GERMAN,
        sliders: sliders,
        getScale: getScale,
        sceneWidth: bind width;
        sceneHeight:bind height;
        surferPanel: bind surferPanel;
        frontColorNode: fxdButtons.getNode("Colorpicker_1"),
        backColorNode:  fxdButtons.getNode("Colorpicker_2"),
        buttonGalleryNode:fxdButtons.getNode("Button_Gallery"),
        buttonInfoNode:fxdButtons.getNode("Button_Info"),
        buttonColorNode:fxdButtons.getNode("Button_Color"),
        buttonGalleryPressedNode:fxdButtons.getNode("Button_Pressed_Gallery"),
        buttonInfoPressedNode:fxdButtons.getNode("Button_Pressed_Info"),
        buttonColorPressedNode:fxdButtons.getNode("Button_Pressed_Color"),
        tabBoxNode:fxdButtons.getNode("Tab_Box")
        galleryTextNode:fxdButtons.getNode("Gallery_Text")
        galleryMiniNode:fxdButtons.getNode("Gallery_Select")
        loadSurface:loadURL
    }
    
    var correctExpression:Boolean= bind surferPanel.correctExpression on replace
    {
        fxdButtons.getNode("Button_Correct").visible=surferPanel.correctExpression;
        fxdButtons.getNode("Button_Wrong").visible=not surferPanel.correctExpression;
    }

    var SurfaceExpression:HBox= new HBox();
    var EqualNull:HBox= new HBox();
    public var surferPanel:FXSurferPanel;
    //var surfaceExpressionField:SwingTextField=new SwingTextField();
    var test:JTextField=new JTextField("x^2+y^2+z^2+2*x*y*z-1");
    //var frontColor: ColorChooser;
    //var backColor: ColorChooser;
    //var zoomShaft:Node;
    //var zoomThumb:Node;
    
    
    
    

        public var scale:Number;
    	public var x: Number;

	public var y: Number;

	public var width: Number on replace
        {
            setTextField();

        };
        public var height: Number on replace
        {
            setTextField();
        };

	public var expression:String;

	public var pos:Number;

	

        function getScale(n:Number, w:Number):Number
        {
            var tmp:Number = w/fxdButtons.layoutBounds.maxX;
            if (tmp*(fxdButtons.layoutBounds.maxY)>n)
            {
                tmp=n/fxdButtons.layoutBounds.maxY;
            }
            return tmp;
        }
    
    function setRenderPanel()
    {
        //fxdButtons.getNode("Surfer").visible=true;
        var R:Bounds=fxdButtons.getNode("Surfer_Rendering").layoutBounds;
        //System.out.println("RenderPanelOrG:{R.minX},{R.minY},{R.maxX},{R.maxY},{R.width},{R.height}");
        surferPanel=FXSurferPanel
                   {
                        width:bind R.height*getScale(height,width),
                        height:bind R.height*getScale(height,width),
                        x:bind (fxdButtons.getNode("Surfer_Rendering").translateX+R.minX)*getScale(height,width),
                        y:bind (fxdButtons.getNode("Surfer_Rendering").translateY+R.minY)*getScale(height,width),
                        frontColor: bind tabField.frontColor.color
                        backColor: bind tabField.backColor.color
                        //scale: bind zoomScale
                    };
        surferPanel.surfaceExpressionChanged(test.getText());

        fxdButtons.getNode("Surfer_Rendering").visible=false;
    }
    
    
    function setTextField()
    {
        var T:Bounds=fxdButtons.getNode("Equation").boundsInParent;
        var T2:Bounds=fxdButtons.getNode("Equals_Zero").boundsInParent;
        //var test:JTextField=new JTextField("x^2+y^2+z^2+2*x*y*z-1");
        fxdButtons.getNode("Equation").visible=false;
        fxdButtons.getNode("Equals_Zero").visible=false;
        //System.out.println("TxtOrG:{T.minX},{T.minY},{T.maxX},{T.maxY},{T.width},{T.height}");
        //System.out.println("TabField:{tabField.backColor.width},{tabField.backColor.height}");
        def textField0:JLabel=new JLabel("=0");
        //textField0.setEditable(false);

        def sw2:SwingComponent=SwingComponent.wrap(textField0);
        sw2.layoutInfo=LayoutInfo
        {
            minWidth: T2.width*getScale(height,width)
            //width: T2.width*getScale(height,width)
            //maxWidth: T2.width*getScale(height,width)
            minHeight: T2.height*getScale(height,width)
            height: T2.height*getScale(height,width)
            maxHeight: T2.height*getScale(height,width)
         };
        def sw:SwingComponent=SwingComponent.wrap(test);
        sw.layoutInfo=LayoutInfo
        {
            minWidth: T.width*getScale(height,width)
            width: T.width*getScale(height,width)
            maxWidth: T.width*getScale(height,width)
            minHeight: T.height*getScale(height,width)
            height: T.height*getScale(height,width)
            maxHeight: T.height*getScale(height,width)
         };
        SurfaceExpression.content=
        [
            sw

        ];
        EqualNull.content=[sw2];
        //surfaceExpressionField.font=Font{size:T.minY*getScale(height,width)*0.08};
        //var f:Font=test.getFont();
        //Nimbus Sans L Regular Surfer.ttf
        //var f:Font=java.awt.Font.createFont(java.awt.Font.TRUETYPE_FONT , new File("{__DIR__}Nimbus Sans L Regular Surfer.ttf"));
        //System.out.println("__DIR__:{__DIR__}");
        
        var input:InputStream = getClass().getResourceAsStream("/de/mfo/jsurfer/gui/Nimbus Sans L Regular Surfer.ttf");
        var f:Font=java.awt.Font.createFont(java.awt.Font.TRUETYPE_FONT , input);
        f=f.deriveFont(T.minY*getScale(height,width)*0.08);
        //var testfont:javafx.scene.text.Font=f;
        test.setFont(f);
        test.setBorder( BorderFactory.createEmptyBorder() );
        textField0.setFont(f);
        textField0.setBorder(BorderFactory.createEmptyBorder());
        SurfaceExpression.layoutX=T.minX*getScale(height,width);
        SurfaceExpression.layoutY=T.minY*getScale(height,width);
        EqualNull.layoutX=T2.minX*getScale(height,width);
        EqualNull.layoutY=T2.minY*getScale(height,width);
    }
    function setButtons()
    {
        /*fxdButtons.getNode("Button_Over_Back").onMousePressed=function(e: MouseEvent): Void {Press("Back"); back();};
	fxdButtons.getNode("Button_Over_Forward").onMousePressed=function(e: MouseEvent): Void {Press("Forward"); forward();};
	fxdButtons.getNode("Button_Over_Backspace").onMousePressed=function(e: MouseEvent): Void {Press("Backspace"); backspace();};

	for (s in["a","b","x","y","z","+","-","*","^","(",")","0","1","2","3","4","5","6","7","8","9","."])
	{
            fxdButtons.getNode("Button_{s}").onMousePressed=function(e: MouseEvent): Void {Press(s); };
            fxdButtons.getNode("Button_Over_{s}").onMousePressed=function(e: MouseEvent): Void {Press(s); };
            fxdButtons.getNode("Button_Pressed_{s}").onMousePressed=function(e: MouseEvent): Void {Press(s); };
	}*/

	for (s in["Cursor_Left","Cursor_Right","Delete","Complete_Delete","a","b","c","d","x","y","z","Plus","Minus","Times","Exp_n","Exp_2","Exp_3","Bracket_open","Bracket_close","0","1","2","3","4","5","6","7","8","9","Comma","Help"])
	{
           fxdButtons.getNode("Button_Over_{s}").visible=false;
           fxdButtons.getNode("Button_Pressed_{s}").visible=false;
           fxdButtons.getNode("Button_{s}").onMouseEntered =function(e: MouseEvent): Void
           {
               if (e.primaryButtonDown) {Press(s);}
               else {MouseOver(s);}

               inside=true;
               for (t in["Cursor_Left","Cursor_Right","Delete","Complete_Delete","a","b","c","d","x","y","z","Plus","Minus","Times","Exp_n","Exp_2","Exp_3","Bracket_open","Bracket_close","0","1","2","3","4","5","6","7","8","9","Comma","Help"])
                  if (t!=s)Standard(t);
           };
           fxdButtons.getNode("Button_{s}").onMouseExited  =function(e: MouseEvent): Void {Standard(s); inside=false;System.out.println("Exit{s}");};
           //fxdButtons.getNode("Button_{s}").onMouseReleased=function(e: MouseEvent): Void {Release(s); setChar(s);};
           fxdButtons.getNode("Button_{s}").onMousePressed=function(e: MouseEvent): Void {Press(s); setChar(s);};
           fxdButtons.getNode("Button_{s}").onMouseClicked=function(e: MouseEvent): Void
           {
               if (e.button== MouseButton.PRIMARY)
               {

                   if(e.primaryButtonDown){Press(s);}
                   else {Release(s); }
               }
           };

           fxdButtons.getNode("Button_Over_{s}").onMouseEntered=function(e: MouseEvent): Void
           {
               if (e.primaryButtonDown) {Press(s);}
               else {MouseOver(s);}
               inside=true;
               for (t in["Cursor_Left","Cursor_Right","Delete","Complete_Delete","a","b","c","d","x","y","z","Plus","Minus","Times","Exp_n","Exp_2","Exp_3","Bracket_open","Bracket_close","0","1","2","3","4","5","6","7","8","9","Comma","Help"])
                  if (t!=s)Standard(t);
           };
           fxdButtons.getNode("Button_Over_{s}").onMouseExited=function(e: MouseEvent): Void {Standard(s); inside=false;System.out.println("Exit{s}");};
           //fxdButtons.getNode("Button_Over_{s}").onMouseReleased=function(e: MouseEvent): Void {Release(s); setChar(s);};
           fxdButtons.getNode("Button_Over_{s}").onMousePressed=function(e: MouseEvent): Void {Press(s);setChar(s); };
           fxdButtons.getNode("Button_Over_{s}").onMouseClicked=function(e: MouseEvent): Void
           {
               if (e.button== MouseButton.PRIMARY)
               {

                   if(e.primaryButtonDown){Press(s);}
                   else {Release(s);/* setChar(s);*/}
               }
           };
           fxdButtons.getNode("Button_Pressed_{s}").onMouseEntered=function(e: MouseEvent): Void
           {
               if (e.primaryButtonDown) {Press(s);}
               else {MouseOver(s);}
               inside=true;
               for (t in["Cursor_Left","Cursor_Right","Delete","Complete_Delete","a","b","c","d","x","y","z","Plus","Minus","Times","Exp_n","Exp_2","Exp_3","Bracket_open","Bracket_close","0","1","2","3","4","5","6","7","8","9","Comma","Help"])
                  if (t!=s)Standard(t);
           };
           fxdButtons.getNode("Button_Pressed_{s}").onMouseExited=function(e: MouseEvent): Void {Standard(s); inside=false;System.out.println("Exit{s}");};
           //fxdButtons.getNode("Button_Pressed_{s}").onMouseReleased=function(e: MouseEvent): Void {Release(s); setChar(s);};
           fxdButtons.getNode("Button_Pressed_{s}").onMousePressed=function(e: MouseEvent): Void {Press(s); setChar(s);};
           fxdButtons.getNode("Button_Pressed_{s}").onMouseClicked=function(e: MouseEvent): Void
           {
               if (e.button== MouseButton.PRIMARY)
               {

                   if(e.primaryButtonDown){Press(s);}
                   else {Release(s); /*setChar(s);*/}
               }
           };
	}
        //surferPanel.drawCoordinatenSystem
        //Button_Axis
        //surferPanel.drawCoordinatenSystem=true;
        //System.out.println("Button Axis inni");
        fxdButtons.getNode("Button_Pressed_Axis").visible=true;
        fxdButtons.getNode("Button_Over_Axis").visible=false;
        fxdButtons.getNode("Button_Axis").visible=false;
        fxdButtons.getNode("Button_Pressed_Axis").onMousePressed=function(e:MouseEvent):Void
        {
            fxdButtons.getNode("Button_Pressed_Axis").visible=false;
            fxdButtons.getNode("Button_Axis").visible=true;
            surferPanel.drawCoordinatenSystem=false;
            //System.out.println("Button_Presse_Axis pressed");

        }
        fxdButtons.getNode("Button_Axis").onMousePressed=function(e:MouseEvent):Void
        {
            fxdButtons.getNode("Button_Pressed_Axis").visible=true;
            fxdButtons.getNode("Button_Axis").visible=false;
            surferPanel.drawCoordinatenSystem=true;
            //System.out.println("Button_Axis pressed");
        }/**/
        
        //language
        //"Button_Cursor_German"
        fxdButtons.getNode("Button_Pressed_German").visible=true;
        fxdButtons.getNode("Button_Over_German").visible=false;
        fxdButtons.getNode("Button_Cursor_German").visible=false;
        fxdButtons.getNode("Button_Pressed_English").visible=false;
        fxdButtons.getNode("Button_Over_English").visible=false;
        fxdButtons.getNode("Button_Cursor_English").visible=true;
        fxdButtons.getNode("Button_Cursor_German").onMousePressed=function(e:MouseEvent):Void
        {
            fxdButtons.getNode("Button_Pressed_German").visible=true;
            fxdButtons.getNode("Button_Cursor_German").visible=false;
            fxdButtons.getNode("Button_Pressed_English").visible=false;
            fxdButtons.getNode("Button_Cursor_English").visible=true;
            language=java.util.Locale.GERMAN;
        }
        fxdButtons.getNode("Button_Cursor_English").onMousePressed=function(e:MouseEvent):Void
        {
            fxdButtons.getNode("Button_Pressed_German").visible=false;
            fxdButtons.getNode("Button_Cursor_German").visible=true;
            fxdButtons.getNode("Button_Pressed_English").visible=true;
            fxdButtons.getNode("Button_Cursor_English").visible=false;
            language=java.util.Locale.ENGLISH;
        }
        

    }




	var inside : Boolean=false;
        var pressedButton : String="";
        //var copynode:Node=javafx.fxd.Duplicator.duplicate(fxdButtons.getNode("Button_a"));
        //copynode.translateX=50;

	public override function create(): Node
	{
            
            setButtons();
            setTextField();


            //copynode.translateY=100;
            //copynode.translateX=100;
            //copynode.scaleX=3;
            test.getDocument().addDocumentListener( DocumentListener
            {
                override function changedUpdate( e )
                {
                    surferPanel.surfaceExpressionChanged(test.getText());
                }
                override function insertUpdate( e )
                {
                    surferPanel.surfaceExpressionChanged(test.getText());
                }
                override function removeUpdate( e )
                {
                    surferPanel.surfaceExpressionChanged(test.getText());
                }
            } );
            
            tabField.set();
            
            setRenderPanel();
            sliders.set();
            def fxlabe=FXLabel
                            {
                                //def jLable:JLabel=new JLabel();
                                string:"=0"
                                Bound:fxdButtons.getNode("Equals_Zero"),
                                getScale: getScale,
                                sceneWidth: bind width;
                                sceneHeight:bind height;
                                faktor:0.08
                            }
                           // fxlabe.set();
            //fxdButtons.opacity=0.5;
		return Group
		{




                        content:
                        [
                            Group
                            {
                            transforms: bind Transform.scale(getScale(height,width),getScale(height,width));

                            content:
                            [
                                    fxdButtons,


                            ]
                            },
                            tabField.frontColor,
                            tabField.backColor,
                            tabField.multiSurfaceInfo,
                            tabField.multiGalleryChooser,
                            tabField.multiGalleryText,
                            tabField.multiGalleryMini,
                            surferPanel,

                            SurfaceExpression,
                            sliders.textValueA,
                            sliders.textValueB,
                            sliders.textValueC,
                            sliders.textValueD,
                            sliders.textValueZoom,
                            sliders.textNameA,
                            sliders.textNameB,
                            sliders.textNameC,
                            sliders.textNameD,
                            sliders.textNameZoom,
                            //fxlabe,
                            javafx.scene.Group{
                                content:[EqualNull]
                            }
                            
                            
                            
                            //copynode

                            //javafx.fxd.Duplicator.duplicate(fxdButtons.getNode("Button_a"))
                            /*Group
                                    {
                                        content:[fxdButtons.getNode("Button_a")]
                                        translateX:0
                                        translateY:0
                                    }*/

                        ]
		}
	}
	public function forward()
	{
                pos=test.getCaretPosition();
                expression=test.getText();
		if (pos<expression.length())pos++;
                //test.setText(expression);
                test.setCaretPosition(pos);
                //System.out.println("zoomScale:{copynode.localToScene(0,0)}");

	}

	public function back()
	{
                pos=test.getCaretPosition();
		if (pos>0)pos--;
                test.setCaretPosition(pos);
	}

	public function backspace()
	{
            pos = test.getSelectionStart();
            expression = test.getText();
            if( pos == test.getSelectionEnd() )
                pos--;// no text is selected; just remove one character
            test.setText( "{expression.substring(0,pos)}{expression.substring(test.getSelectionEnd())}" );
            test.setCaretPosition( pos );
	}
        
        public function CompleteDelete()
        {
            pos=0;
            test.setText("");
            test.setCaretPosition(pos);
        }

        public function insertStringInTextfield(c:String)
        {
            pos=test.getCaretPosition();
                expression=test.getText();
		expression="{expression.substring(0,pos)}{c}{expression.substring(pos)}";
		pos+=c.length();
               test.setText(expression);
                test.setCaretPosition(pos);
        }

	public function setChar(c:String )
	{
           //there is no switch case in javafx
           //["Cursor_Left","Cursor_Right","Delete","Complete_Delete","a","b","c","d","x","y","z",
           // "Plus","Minus","Times","Exp_n","Exp_2","Exp_3","Bracket_open","Bracket_close",
           // "0","1","2","3","4","5","6","7","8","9","Comma","Wrong","Correct","Help"]
           if (c=="a" or c=="b" or c=="c" or c=="d" or c=="1" or c=="2" or c=="3" or
               c=="4" or c=="5" or c=="6" or c=="7" or c=="8" or c=="9" or c=="0"or
               c=="x"or c=="y"or c=="z")
           {
               insertStringInTextfield(c);
           }
           else if (c=="Cursor_Left"){back();}
           else if (c=="Cursor_Right"){forward();}
           else if (c=="Delete"){backspace();}
           else if (c=="Complete_Delete"){CompleteDelete();}
           else if (c=="Plus"){insertStringInTextfield("+");}
           else if (c=="Minus"){insertStringInTextfield("-");}
           else if (c=="Times"){insertStringInTextfield("*");}
           else if (c=="Exp_n"){insertStringInTextfield("^");}
           else if (c=="Exp_2"){insertStringInTextfield("^2");}
           else if (c=="Exp_3"){insertStringInTextfield("^3");}
           else if (c=="Bracket_open"){insertStringInTextfield("(");}
           else if (c=="Bracket_close"){insertStringInTextfield(")");}
           else if (c=="Comma"){insertStringInTextfield(".");}
           else if (c=="Correct"){/*Nothing Happens*/}
           else if (c=="Wrong"){/*ToDo NahrichtenFensten ausgeben*/}
           else if (c=="Help"){/*ToDo Help*/tabField.setHelpState();}

            /*if (c!="Back" and c!="Forward" and c!="Backspace")
            {
                pos=test.getCaretPosition();
                expression=test.getText();
		expression="{expression.substring(0,pos)}{c}{expression.substring(pos)}";
		pos++;
               test.setText(expression);
                test.setCaretPosition(pos);
            }
            else
            {
                if(c=="Back")back();
                if(c=="Forward")forward();
                if(c=="Backspace")backspace();
            }*/


	}
	function Press(s: String)
	{
		fxdButtons.getNode("Button_{s}").visible=false;
		fxdButtons.getNode("Button_Over_{s}").visible=false;
		fxdButtons.getNode("Button_Pressed_{s}").visible=true;
                pressedButton=s;
	}
	function Release(s: String)
	{
		if(inside) {MouseOver(s);}
		else {Standard(s);}
                pressedButton="";
	}

	function MouseOver(s: String)
	{
            if (s!=pressedButton)
            {
		fxdButtons.getNode("Button_{s}").visible=false;
		fxdButtons.getNode("Button_Over_{s}").visible=true;
		fxdButtons.getNode("Button_Pressed_{s}").visible=false;/**/
            }
	}

	function Standard(s: String)
	{
		fxdButtons.getNode("Button_{s}").visible=true;
		fxdButtons.getNode("Button_Over_{s}").visible=false;
		fxdButtons.getNode("Button_Pressed_{s}").visible=false;
                if (pressedButton==s){pressedButton="";System.out.println("Standard {s}");}
	}
        



    function load():Void
    {
       var fc:JFileChooser  = new JFileChooser();
       fc.setFileSelectionMode( JFileChooser.FILES_ONLY );
       fc.setAcceptAllFileFilterUsed( false );
       var jsurfFilter:JSurfFilter  = new JSurfFilter();
       fc.addChoosableFileFilter( jsurfFilter );

       var returnVal:Integer = fc.showOpenDialog( surferPanel.renderer );
       if( returnVal == JFileChooser.APPROVE_OPTION )
       {
          var f:java.io.File  = fc.getSelectedFile();
          f = jsurfFilter.ensureExtension( f );
          loadURL(f.toURL());
          /*try
          {
             surferPanel.renderer.loadFromFile( f.toURL());
             surferPanel.renderer.repaintImage();
             
             //renderer.getAlgebraicSurfaceRenderer().setParameterValue("a", a);
             surferPanel.a=surferPanel.renderer.getAlgebraicSurfaceRenderer().getParameterValue("a");
             System.out.println("loaded Par a:{surferPanel.renderer.getAlgebraicSurfaceRenderer().getParameterValue("a")}");
             surferPanel.b=surferPanel.renderer.getAlgebraicSurfaceRenderer().getParameterValue("b");
             test.setText(surferPanel.renderer.getAlgebraicSurfaceRenderer().getSurfaceFamilyString());
           }
           catch(e: java.lang.Exception  )
           {
             var  message:String= "Could not save to file \" {f.getName()  } \".";
             if( e.getMessage() != null )
             message = "{message}\n\nMessage: {e.getMessage()}";
             JOptionPane.showMessageDialog( null, message, "Error", JOptionPane.OK_OPTION );
           }*/
        }
      }

      function save():Void
      {
        var fc:JFileChooser  = new JFileChooser();
        fc.setFileSelectionMode( JFileChooser.FILES_ONLY );
        fc.setAcceptAllFileFilterUsed( false );
        var jsurfFilter:JSurfFilter  = new JSurfFilter();
        fc.addChoosableFileFilter( jsurfFilter );

        var returnVal:Integer = fc.showSaveDialog( surferPanel.renderer );
        if( returnVal == JFileChooser.APPROVE_OPTION )
        {
            var f:java.io.File  = fc.getSelectedFile();
            f = jsurfFilter.ensureExtension( f );
            try
            {
                //file.toURL()
                surferPanel.renderer.saveToFile( f.toURL());
                surferPanel.renderer.repaintImage();
                //renderer.saveToPNG( f, 1024, 1024 );
            }
            catch(e: java.lang.Exception  )
            {
                var  message:String= "Could not save to file \" {f.getName()  } \".";
                if( e.getMessage() != null )
                    message = "{message}\n\nMessage: {e.getMessage()}";
                JOptionPane.showMessageDialog( null, message, "Error", JOptionPane.OK_OPTION );
            }
        }
      }


}

