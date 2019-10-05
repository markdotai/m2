using Toybox.Application;
using Toybox.WatchUi;

class myApp extends Application.AppBase
{
	var mainView = null;

    function initialize()
    {
        AppBase.initialize();
    }

    //function onStart(state)    // onStart() is called on application start up
    //{
    //    //System.println("app onStart");
    //}

    function onStop(state)    // onStop() is called when your application is exiting
    {
        //System.println("app onStop");

		if (null != mainView)
		{
			mainView.onStop();
		}
    }

    (:m2face)
    function getInitialView()    // Return the initial view of your application here
    {
        //System.println("mPropertiesChanged=" + mPropertiesChanged);

    	mainView = new myFaceView();
        //if (Toybox.WatchUi has :WatchFaceDelegate)
        //{
        //	return [mainView, new TestDelegate()];
        //}
        //else
        {
        	return [mainView];
        }
    }

	(:m2app)
    function getInitialView()    // Return the initial view of your application here
    {
        //System.println("mPropertiesChanged=" + mPropertiesChanged);

    	mainView = new myAppView();
    	
    	var appDelegate = new myAppDelegate();
    	appDelegate.setView(mainView.sharedView);

       	return [mainView, appDelegate];
    }

    function onSettingsChanged()    // New app settings have been received so trigger a UI update
    {
        //System.println("onSettingsChanged");
        //System.println("mPropertiesChanged=" + mPropertiesChanged);

		if (null != mainView)
		{
			mainView.onSettingsChanged();
		}
    }
}

(:m2face)
class myFaceView extends WatchUi.WatchFace
{
	var sharedView = new myView(); 

    function initialize()
    {
        WatchFace.initialize();
        
        sharedView.initialize();
    }

    function onLayout(dc)
    {
    	sharedView.onLayout(dc);
    }

    function onStop()
    {
    	sharedView.onStop();
    }

    function onShow()
    {
    	sharedView.onShow();
    }

    function onHide()
    {
    	sharedView.onHide();
    }

    function onExitSleep()
    {
    	sharedView.onExitSleep();
    }

    function onEnterSleep()
    {
    	sharedView.onEnterSleep();
    }

    function onSettingsChanged()
    {
    	sharedView.onSettingsChanged();
    }

    function onUpdate(dc)
    {
        //View.onUpdate(dc);	// Call the parent onUpdate function to redraw the layout
        
    	sharedView.onUpdate(dc);
    }

    function onPartialUpdate(dc)
    {
    	sharedView.onPartialUpdate(dc);
    }
}

(:m2app)
class myAppView extends WatchUi.View
{
	var sharedView = new myEditorView(); 

    function initialize()
    {
        View.initialize();

        sharedView.initialize();
    }

    function onLayout(dc)
    {
    	sharedView.onLayout(dc);
    }

    function onStop()
    {
    	sharedView.onStop();
    }

    function onShow()
    {
    	sharedView.onShow();
    }

    function onHide()
    {
    	sharedView.onHide();
    }

    function onSettingsChanged()
    {
    	sharedView.onSettingsChanged();
    }

    function onUpdate(dc)
    {
        //View.onUpdate(dc);	// Call the parent onUpdate function to redraw the layout
        
    	sharedView.onUpdate(dc);
    }
}

(:m2app)
class myAppDelegate extends WatchUi.BehaviorDelegate
{
	var mainView;

	function setView(sharedView)
	{
		mainView = sharedView;
	}

    function initialize()
    {
        BehaviorDelegate.initialize();
    }

    function onMenu()	// hold left middle button
    {
    	return mainView.onMenu();
    }

    function onBack()	// tap right bottom
    {
    	// return false here to exit the app
    	return mainView.onBack();
    }

    function onNextPage()	// tap left bottom
    {
    	return mainView.onNextPage();
    }

    function onPreviousPage()	// tap left middle
    {
    	return mainView.onPreviousPage();
    }

    function onSelect()		// tap right top
    {
    	return mainView.onSelect();
    }

    //function onNextMode()
    //{
    //    System.println("onNextMode");
	//
    //	WatchUi.requestUpdate();
    //
    //    return true;
    //}

    //function onPreviousMode()
    //{
    //    System.println("onPreviousMode");
	//
    //	WatchUi.requestUpdate();
    //
    //    return true;
    //}

    function onKey(keyEvent) 	// a physical button has been pressed and released. 
    {
    	return mainView.onKey(keyEvent);
    }
    
    function onKeyPressed(keyEvent) 	// a physical button has been pressed down. 
    {
    	return mainView.onKeyPressed(keyEvent);
    }
    
    function onKeyReleased(keyEvent) 	// a physical button has been released. 
    {
    	return mainView.onKeyReleased(keyEvent);
    }
        
    function onTap(clickEvent)		// a screen tap event has occurred. 
    {
    	return mainView.onTap(clickEvent);
    }

    function onHold(clickEvent)		// a touch screen hold event has occurred. 
    {
    	return mainView.onHold(clickEvent);
    }
    
    function onRelease(clickEvent) 		// a touch screen release event has occurred. 
    {
    	return mainView.onRelease(clickEvent);
    }
    
    function onSwipe(swipeEvent) 	// a touch screen swipe event has occurred. 
    {
    	return mainView.onSwipe(swipeEvent);
    }    
}