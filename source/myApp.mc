using Toybox.Application;
using Toybox.WatchUi;

class myApp extends Application.AppBase
{
	var mainView = null;

    function initialize()
    {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    //function onStart(state)
    //{
    //    //System.println("app onStart");
    //}

    // onStop() is called when your application is exiting
    function onStop(state)
    {
        //System.println("app onStop");

		if (null != mainView)
		{
			mainView.onStop();
		}
    }

    // Return the initial view of your application here
    function getInitialView()
    {
        //System.println("mPropertiesChanged=" + mPropertiesChanged);

    	mainView = new myView();
        //if (Toybox.WatchUi has :WatchFaceDelegate)
        //{
        //	return [mainView, new TestDelegate()];
        //}
        //else
        {
        	return [mainView];
        }
    }

    // New app settings have been received so trigger a UI update
    function onSettingsChanged()
    {
        //System.println("onSettingsChanged");
        //System.println("mPropertiesChanged=" + mPropertiesChanged);

		if (null != mainView)
		{
			mainView.onSettingsChanged();
		}
    }
}