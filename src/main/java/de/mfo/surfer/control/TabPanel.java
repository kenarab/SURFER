package de.mfo.surfer.control;

import de.mfo.surfer.Main;
import de.mfo.surfer.util.FXUtils;
import javafx.beans.property.IntegerProperty;
import javafx.beans.property.SimpleIntegerProperty;
import javafx.event.ActionEvent;
import javafx.event.EventHandler;
import javafx.geometry.Bounds;
import javafx.scene.control.Label;
import javafx.scene.layout.Pane;
import javafx.scene.layout.Region;
import javafx.scene.Node;
import de.mfo.surfer.util.Preferences;
import static de.mfo.surfer.util.L.lb;

public class TabPanel extends Region
{
    SimpleIntegerProperty activeTab;

    public TabPanel( Pane galleryPanel, Pane infoPanel, Pane colorPanel )
    {
        super();

        activeTab = new SimpleIntegerProperty( Preferences.General.getInitiallyOpenedTab() );

        initTabLabel( "Tab_Text_Gallery", "start" );
        initTabLabel( "Tab_Text_Info", "info" );
        initTabLabel( "Tab_Text_Color", "colors" );

        initTabButton( "Gallery", e -> activeTab.set( 0 ) );
        initTabButton( "Info", e -> activeTab.set( 1 ) );
        initTabButton( "Color", e -> activeTab.set( 2 ) );

        initTabContent( galleryPanel, 0 );
        initTabContent( infoPanel, 1 );
        initTabContent( colorPanel, 2 );
    }

    private void initTabLabel( String placeholderId, String lbId )
    {
        Label label = new Label();
        FXUtils.resizeRelocateTo( label, FXUtils.setVisible( Main.fxmlLookup( "#" + placeholderId ), false ) );
        label.textProperty().bind( lb( lbId ) );
        getChildren().add( label );
    }

    private void initTabButton( String suffix, EventHandler< ActionEvent > handler )
    {
        SceneNodeButton button = new SceneNodeButton(
            Main.fxmlLookup( "#Button_" + suffix ),
            Main.fxmlLookup( "#Button_Over_" + suffix ),
            Main.fxmlLookup( "#Button_Pressed_" + suffix )
        );
        button.setOnAction( handler );
        getChildren().add( button );
    }

    private void initTabContent( Pane tabContent, int index )
    {
        FXUtils.resizeRelocateTo( tabContent, FXUtils.setVisible( Main.fxmlLookup( "#Tab_Box" ), false ) );
        tabContent.visibleProperty().bind( activeTab.isEqualTo( index ) );
        tabContent.disableProperty().bind( activeTab.isNotEqualTo( index ) );
        getChildren().add( tabContent );
    }

    public int getActiveTabIndex()
    {
        return activeTab.get();
    }

    public void setActiveTabIndex( int value )
    {
        activeTab.set( value );
    }

    public IntegerProperty activeTabIndexProperty()
    {
        return activeTab;
    }

    @Override
    public String getUserAgentStylesheet()
    {
        return SceneNodeSliderWithNameAndValue.class.getResource( "../css/style.css" ).toExternalForm();
    }
}