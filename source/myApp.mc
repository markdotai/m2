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
        //if (Toybox.WatchUi has :WatchFaceDelegate)
        //{
        //	return [mainView, new TestDelegate()];
        //}
        //else
        {
        	return [mainView, new myAppDelegate()];
        }
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
	var sharedView = new myView(); 

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
    function initialize()
    {
        BehaviorDelegate.initialize();
    }

    function onMenu()	// hold left middle button
    {
    	WatchUi.requestUpdate();
    
        //WatchUi.pushView(new Rez.Menus.MainMenu(), new testAppMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

    function onBack()	// tap right bottom
    {
    	WatchUi.requestUpdate();
    
    	// return false here to exit the app
    
        return true;
    }

    function onNextPage()	// tap left bottom
    {
        //System.println("onNextPage");

    	WatchUi.requestUpdate();
    
        return true;
    }

    function onPreviousPage()	// tap left middle
    {
        //System.println("onPreviousPage");

    	WatchUi.requestUpdate();
    
        return true;
    }

    function onSelect()		// tap right top
    {
        //System.println("onSelect");

    	WatchUi.requestUpdate();
    
        return true;
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
}