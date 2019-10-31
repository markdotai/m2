using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Lang;
using Toybox.Application;
using Toybox.StringUtil;
using Toybox.Time;
using Toybox.Timer;

using Application.Properties as applicationProperties;
using Application.Storage as applicationStorage;

//class myView extends WatchUi.WatchFace
class myView
{
	//var forceMemoryTest = new[512 /*1024*6*/]b;
	//const forceTestFont = false;
	//const forceTestLocation = true;
	//const forceClearStorage = true;
	//const forceDemoProfiles = false;
	//const forceDemoFontStyles = false;

//	(:exclude)	// always excluded
//	function testExcludeFunction()
//	{
//	}
//	
//	(:m2face)	// in m2face - excluded in m2app
//	function testExcludeFunction()
//	{
//	}
//	
//	(:m2app)	// in m2app - excluded in m2face
//	function testExcludeFunction()
//	{
//	}

	const PROFILE_VERSION = 21;			// a version number
	const PROFILE_NUM_PRESET = 17;		// number of preset profiles (in the jsondata resource)

	const PROFILE_NUM_USER = 24;		// number of user profiles

	var updateTimeNowValue;
	var updateTimeTodayValue;
	var updateTimeZoneOffset;

	var firstUpdateSinceInitialize = true;

	var settingsHaveChanged = false;
	
	//var updateLastSec;		// just needed for bug in CIQ
	//var updateLastMin;		// just needed for bug in CIQ

	var lastPartialUpdateSec;

	var glanceActive = false;
	
	//enum
	//{
	//	//!APPCASE_ANY = 0,
	//	//APPCASE_UPPER = 1,
	//	//APPCASE_LOWER = 2
	//}
	
	// prop or "property" variables - are the ones which we store in onUpdate, so they don't change when they are used in onPartialUpdate
	var propBackgroundColor;
	var propAddLeadingZero = false;
    var propFieldFontSystemCase = 0;
    var propFieldFontUnsupported;
	var fontFieldUnsupportedResource = null;
    var propMoveBarAlertTriggerLevel = 0; 
    var propBatteryHighPercentage = 75.0;
	var propBatteryLowPercentage = 25.0;	
	var prop2ndTimeZoneOffset = 0;
    
    var propSecondIndicatorOn = false;
	var propSecondResourceIndex = 0;
	var propSecondMoveInABit;
    var propSecondRefreshStyle;
	//enum
	//{
	//	REFRESH_EVERY_SECOND = 0,
	//	REFRESH_EVERY_MINUTE = 1,
	//	REFRESH_ALTERNATE_MINUTES = 2
	//}
	//var propSecondIndicatorStyle;
    		    
//    const PROFILE_NUM_PROPERTIES = 38;
    //const PROFILE_PROPERTY_COLON = 36;
    //const PROFILE_PROPERTY_2ND_TIME_ZONE_OFFSET = 37;
    // 0 = profile name
    // 1 = background color
    // 2 = time on
    // 3 = add leading zero (time military)
    // 4 = time hour font
    // 5 = time hour color
    // 6 = time minute font
    // 7 = time minute color
    // 8 = time italic
    // 9 = time y offset
    // 10 = second indicator on
    // 11 = second indicator style
    // 12 = second refresh style
    // 13 = second color
    // 14 = second color 5
    // 15 = second color 10
    // 16 = second color 15
    // 17 = second color 0
    // 18 = second color demo
    // 19 = second move in a bit
    // 20 = outer on
    // 21 = outer mode
    // 22 = outer color filled
    // 23 = outer color unfilled
    // 24 = field font
    // 25 = field custom weight
    // 26 = field system case
    // 27 = field names font for unsupported languages
    // 28 = field move bar off color
    // 29 = field move bar alert trigger level
    // 30 = field battery high percentage
    // 31 = field battery low percentage
    // 32 = demo font styles
    // 33 = demo second styles
    // 34 = demo display
    // 35 = glance profile
    // 36 = time colon separator
    // 37 = 2nd time zone offset
    
//	function getBooleanFromArray(pArray, p)
//	{
//		var v = false;
//		if ((p>=0) && (p<pArray.size()) && (pArray[p]!=null) && (pArray[p] instanceof Boolean))
//		{
//			v = pArray[p];
//		}
//		return v;
//	}
	
//	function getNumberFromArray(pArray, p)
//	{
//		var v = 0;
//		if ((p>=0) && (p<pArray.size()) && (pArray[p]!=null) && !(pArray[p] instanceof Boolean))
//		{
//			v = pArray[p].toNumber();
//			if (v == null)
//			{
//				v = 0;
//			}
//		}
//		return v;
//	}
		
//	function getColorIndexFromArray(pArray, p, minV)
//	{
//		return getMinMax(getNumberFromArray(pArray, p), minV, 63);
//	}

//	function getColorFromArray(pArray, p, minV)
//	{				
//		return getColor64(getColorIndexFromArray(pArray, p, minV));
//	}

//	function getStringFromArray(pArray, p)
//	{	
//		var v = "";
//		if ((p>=0) && (p<pArray.size()) && (pArray[p]!=null))
//		{
//			v = pArray[p].toString();
//		}
//		return v;
//	}
	
//	function getCharArrayFromArray(pArray, p)
//	{	
//		return getStringFromArray(p).toCharArray();
//	}

	var hasDoNotDisturb;
	var hasLTE;
	var hasElevationHistory;
	var hasPressureHistory;
	var hasHeartRateHistory;

	function lteConnected()
	{
		return (hasLTE && (System.getDeviceSettings().connectionInfo[:lte].state==System.CONNECTION_STATE_CONNECTED));
    }
        	
	var fieldActivePhoneStatus = null;
	var fieldActiveNotificationsStatus = null;
	var fieldActiveNotificationsCount = null;
	var fieldActiveLTEStatus = null;

	var profileActive = 0;		// currently active profile
	var profileDelayEnd = 0;	// after manually changing settings then any automatic profile loads get delayed until this moment
	var profileGlance = -1;		// -1 means no glance profile active
	var profileGlanceReturn = 0;
	var profileRandom = -1;		// -1 means no random profile active
	var profileRandomEnd = 0;
	var profileRandomLastMin = -1;		// last minute number that we did the random checks

	var honestyCheckbox = false;

	var demoProfilesOn = false;
	var demoProfilesFirst = PROFILE_NUM_USER;
	var demoProfilesLast = PROFILE_NUM_USER+PROFILE_NUM_PRESET-1;
	var demoProfilesCurrentProfile = -1;
	var demoProfilesCurrentEnd = 0;

	var propSunAltitudeAdjust = false;
	var propNonActiveCalories = 0;

	// if any of these numbers below change, then also need to modify:
	//     	- FIELD_SHAPE_CIRCLE, as they are in the same order
	//		- the demo display drawing mode 
	//!const iconsString = "ABCDEFGHIJKLMNOPQRSTUVWX";
	//const ICONS_FIRST_CHAR_ID = 65;
	//
	// 0 = 48 = move bar
	// 1 = 49 = move bar solid
	//
	// A = 65 = circle
	// B = 66 = circle solid
	// C = 67 = rounded
	// D = 68 = rounded solid
	// E = 69 = square
	// F = 70 = square solid
	// G = 71 = triangle
	// H = 72 = triangle solid
	// I = 73 = diamond
	// J = 74 = diamond solid
	// K = 75 = star
	// L = 76 = star solid
	//
	// M = 77 = alarm
	// N = 78 = lock
	// O = 79 = phone
	// P = 80 = notification
	// Q = 81 = figure
	// R = 82 = battery
	// S = 83 = battery solid
	// T = 84 = bed
	// U = 85 = flower
	// V = 86 = footsteps
	// W = 87 = network
	// X = 88 = stairs
	// Y = 89 = phone (handset)
	// Z = 90 = moving clock
	// [ = 91 = fire
	// \ = 92 = heart
	// ] = 93 = sunrise
	// ^ = 94 = sunset
	// _ = 95 = sun
	// ' = 96 = moon
	// a = 97 = mountain
	
	//enum
	//{
	//	STATUS_ALWAYSON = 0,
	//	STATUS_DONOTDISTURB_ON = 1,
	//	STATUS_DONOTDISTURB_OFF = 2,
	//	STATUS_ALARM_ON = 3,
	//	STATUS_ALARM_OFF = 4,
	//	STATUS_NOTIFICATIONS_PENDING = 5,
	//	STATUS_NOTIFICATIONS_NONE = 6,
	//	STATUS_PHONE_CONNECTED = 7,
	//	STATUS_PHONE_NOT = 8,
	//	STATUS_LTE_CONNECTED = 9,
	//	STATUS_LTE_NOT = 10,
	//	STATUS_BATTERY_HIGHORMEDIUM = 11,
	//	STATUS_BATTERY_HIGH = 12,
	//	STATUS_BATTERY_MEDIUM = 13,
	//	STATUS_BATTERY_LOW = 14,
	//	STATUS_MOVEBARALERT_TRIGGERED = 15,
	//	STATUS_MOVEBARALERT_NOT = 16,
	//	STATUS_AM = 17,
	//	STATUS_PM = 18,
	//	STATUS_2ND_AM = 19,
	//	STATUS_2ND_PM = 20,
	//	STATUS_SUNEVENT_RISE = 21,
	//	STATUS_SUNEVENT_SET = 22,
	//	STATUS_GLANCE_ON = 23,
	//	STATUS_GLANCE_OFF = 24,
	//
	//	STATUS_NUM = 25
	//}
	
	//enum
	//{
    //	FIELD_EMPTY = 0,
	//
    //	FIELD_HOUR = 1,
    //	FIELD_MINUTE = 2,
    //	FIELD_DAY_NAME = 3,
	//	FIELD_DAY_OF_WEEK = 4,
	//	FIELD_DAY_OF_MONTH = 5,
	//	FIELD_DAY_OF_MONTH_XX = 6,
	//	FIELD_DAY_OF_YEAR = 7,
	//	FIELD_DAY_OF_YEAR_XXX = 8,
	//	FIELD_MONTH_NAME = 9,
	//	FIELD_MONTH_OF_YEAR = 10,
	//	FIELD_MONTH_OF_YEAR_XX = 11,
	//	FIELD_YEAR_XX = 12,
	//	FIELD_YEAR_XXXX = 13,
	//	FIELD_WEEK_ISO_XX = 14,
	//	FIELD_WEEK_ISO_WXX = 15,
	//	FIELD_YEAR_ISO_WEEK_XXXX = 16,
	//	FIELD_WEEK_CALENDAR_XX = 17,
	//	FIELD_YEAR_CALENDAR_WEEK_XXXX = 18,
	//	FIELD_AM = 19,
	//	FIELD_PM = 20,
	//
	//	FIELD_SEPARATOR_SPACE = 21,
	//	//!FIELD_SEPARATOR_SLASH_FORWARD = 22,
	//	//!FIELD_SEPARATOR_SLASH_BACK = 23,
	//	//!FIELD_SEPARATOR_COLON = 24,
	//	//!FIELD_SEPARATOR_MINUS = 25,
	//	//!FIELD_SEPARATOR_DOT = 26,
	//	//!FIELD_SEPARATOR_COMMA = 27,
	//	FIELD_SEPARATOR_PERCENT = 28,
	//
	//	FIELD_STEPSCOUNT = 31,
	//	FIELD_STEPSGOAL = 32,
	//	FIELD_FLOORSCOUNT = 33,
	//	FIELD_FLOORSGOAL = 34,
	//	FIELD_NOTIFICATIONSCOUNT = 35,
	//	FIELD_BATTERYPERCENTAGE = 36,
	//	FIELD_MOVEBAR = 37,
	//
	//	FIELD_SHAPE_CIRCLE = 41,
	//	//!FIELD_SHAPE_CIRCLE_SOLID = 42,
	//	//!FIELD_SHAPE_ROUNDED = 43,
	//	//!FIELD_SHAPE_ROUNDED_SOLID = 44,
	//	//!FIELD_SHAPE_SQUARE = 45,
	//	//!FIELD_SHAPE_SQUARE_SOLID = 46,
	//	//!FIELD_SHAPE_TRIANGLE = 47,
	//	//!FIELD_SHAPE_TRIANGLE_SOLID = 48,
	//	//!FIELD_SHAPE_DIAMOND = 49,
	//	//!FIELD_SHAPE_DIAMOND_SOLID = 50,
	//	//!FIELD_SHAPE_STAR = 51,
	//	//!FIELD_SHAPE_STAR_SOLID = 52,
	//	//!FIELD_SHAPE_ALARM = 53,
	//	//!FIELD_SHAPE_LOCK = 54,
	//	//!FIELD_SHAPE_PHONE = 55,
	//	//!FIELD_SHAPE_NOTIFICATION = 56,
	//	//!FIELD_SHAPE_FIGURE = 57,
	//	//!FIELD_SHAPE_BATTERY = 58,
	//	//!FIELD_SHAPE_BATTERY_SOLID = 59,
	//	//!FIELD_SHAPE_BED = 60,
	//	//!FIELD_SHAPE_FLOWER = 61,
	//	//!FIELD_SHAPE_FOOTSTEPS = 62,
	//	//!FIELD_SHAPE_NETWORK = 63,
	//	//!FIELD_SHAPE_STAIRS = 64,
	//	//!FIELD_SHAPE_PHONE_HANDSET = 65,
	//	//!FIELD_SHAPE_STOPWATCH = 66,
	//	//!FIELD_SHAPE_FIRE = 67,
	//	//!FIELD_SHAPE_HEART = 68,
	//	//!FIELD_SHAPE_SUNRISE = 69,
	//	//!FIELD_SHAPE_SUNSET = 70,
	//	//!FIELD_SHAPE_SUN = 71,
	//	//!FIELD_SHAPE_MOON = 72,
	//	//!FIELD_SHAPE_MOUNTAIN = 73,
	//
	//	FIELD_HEART_MIN = 76
	//	FIELD_HEART_MAX = 77
	//	FIELD_HEART_AVERAGE = 78
	//	FIELD_HEART_LATEST = 79
	//	FIELD_HEART_BARS = 80
	//	FIELD_HEART_AXES = 81
	//	FIELD_SUNRISE_HOUR = 82,
	//	FIELD_SUNRISE_MINUTE = 83,
	//	FIELD_SUNSET_HOUR = 84,
	//	FIELD_SUNSET_MINUTE = 85,
	//	FIELD_SUNEVENT_HOUR = 86,
	//	FIELD_SUNEVENT_MINUTE = 87,
	//	FIELD_2ND_HOUR = 88,
	//	FIELD_CALORIES = 89,
	//	FIELD_ACTIVE_CALORIES = 90,
	//	FIELD_INTENSITY = 91,
	//	FIELD_INTENSITY_GOAL = 92,
	//	FIELD_SMART_GOAL = 93,
	//	FIELD_DISTANCE = 94,
	//	FIELD_DISTANCE_UNITS = 95,
	//	FIELD_PRESSURE = 96,
	//	FIELD_PRESSURE_UNITS = 97,
	//	FIELD_ALTITUDE = 98,
	//	FIELD_ALTITUDE_UNITS = 99,
	//
	//	//!FIELD_UNUSED
	//}
	
	var colorArray = new[64]b;

	const COLOR_NOTSET = -1;	// just used in the code to indicate no color set
	
	function getColor64(i)
	{
		if (i<0 || i>=64)
		{
			return COLOR_NOTSET; 
		}
	
		// 0x00 = 000, 0x01 = 005, 0x02 = 00A, 0x03 = 00F
		// 0x04 = 050, 0x05 = 055, 0x06 = 05A, 0x07 = 05F
		// 0x08 = 0A0, 0x09 = 0A5, 0x0A = 0AA, 0x0B = 0AF
		// 0x0C = 0F0, 0x0D = 0F5, 0x0E = 0FA, 0x0F = 0FF
		//
		// 0x10 = 500, 0x20 = A00, 0x30 = F00
//		var colorArray = [
//			// grayscale......
//			//      0            1            2           3
//			// 000000       555555       AAAAAA      FFFFFF
//			(0x00<<24) | (0x15<<16) | (0x2A<<8) | (0x3F),
//			// bright......
//			//      4            5            6           7
//			// FFFF00       AAFF00       55FF00      00FF00
//			(0x3C<<24) | (0x2C<<16) | (0x1C<<8) | (0x0C),
//			//      8            9           10          11
//			// 00FF55       00FFAA       00FFFF      00AAFF
//			(0x0D<<24) | (0x0E<<16) | (0x0F<<8) | (0x0B),
//			//     12           13           14          15
//			// 0055FF       0000FF       5500FF      AA00FF
//			(0x07<<24) | (0x03<<16) | (0x13<<8) | (0x23),
//			//     16           17           18          19
//			// FF00FF       FF00AA       FF0055      FF0000
//			(0x33<<24) | (0x32<<16) | (0x31<<8) | (0x30),
//							          // dim.......
//			//     20           21           22          23
//			// FF5500       FFAA00       AAAA55      55AA55
//			(0x34<<24) | (0x38<<16) | (0x29<<8) | (0x19),
//			//     24           25           26          27
//			// 55AAAA       5555AA       AA55AA      AA5555
//			(0x1A<<24) | (0x16<<16) | (0x26<<8) | (0x25),
//			// pale......
//			//     28           29           30          31
//			// FFFF55       AAFF55       55FF55      55FFAA
//			(0x3D<<24) | (0x2D<<16) | (0x1D<<8) | (0x1E),
//			//     32           33           34          35
//			// 55FFFF       55AAFF       5555FF      AA55FF
//			(0x1F<<24) | (0x1B<<16) | (0x17<<8) | (0x27),
//			//     36           37           38          39
//			// FF55FF       FF55AA       FF5555      FFAA55
//			(0x37<<24) | (0x36<<16) | (0x35<<8) | (0x39),
//			// palest......
//			//     40           41           42          43
//			// FFFFAA       AAFFAA       AAFFFF      AAAAFF
//			(0x3E<<24) | (0x2E<<16) | (0x2F<<8) | (0x2B),
//									  // dark......
//			//     44           45           46          47
//			// FFAAFF       FFAAAA       AAAA00      55AA00
//			(0x3B<<24) | (0x3A<<16) | (0x28<<8) | (0x18),
//			//     48           49           50          51
//			// 00AA00       00AA55       00AAAA      0055AA
//			(0x08<<24) | (0x09<<16) | (0x0A<<8) | (0x06),
//			//     52           53           54          55
//			// 0000AA       5500AA       AA00AA      AA0055
//			(0x02<<24) | (0x12<<16) | (0x22<<8) | (0x21),
//									  // darkest......
//			//     56           57           58          59
//			// AA0000       AA5500       555500      005500
//			(0x20<<24) | (0x24<<16) | (0x14<<8) | (0x04),
//			//     60           61           62          63
//			// 005555       000055       550055      550000
//			(0x05<<24) | (0x01<<16) | (0x11<<8) | (0x10),
//		];

//			[
//			<!-- (0x00<<24) | (0x15<<16) | (0x2A<<8) | (0x3F) --> 1387071,
//			<!-- (0x3C<<24) | (0x2C<<16) | (0x1C<<8) | (0x0C) --> 1009523724,
//			<!-- (0x0D<<24) | (0x0E<<16) | (0x0F<<8) | (0x0B) --> 219025163,
//			<!-- (0x07<<24) | (0x03<<16) | (0x13<<8) | (0x23) --> 117642019,
//			<!-- (0x33<<24) | (0x32<<16) | (0x31<<8) | (0x30) --> 858927408,
//			<!-- (0x34<<24) | (0x38<<16) | (0x29<<8) | (0x19) --> 876095769,
//			<!-- (0x1A<<24) | (0x16<<16) | (0x26<<8) | (0x25) --> 437659173,
//			<!-- (0x3D<<24) | (0x2D<<16) | (0x1D<<8) | (0x1E) --> 1026366750,
//			<!-- (0x1F<<24) | (0x1B<<16) | (0x17<<8) | (0x27) --> 521869095,
//			<!-- (0x37<<24) | (0x36<<16) | (0x35<<8) | (0x39) --> 926299449,
//			<!-- (0x3E<<24) | (0x2E<<16) | (0x2F<<8) | (0x2B) --> 1043214123,
//			<!-- (0x3B<<24) | (0x3A<<16) | (0x28<<8) | (0x18) --> 993667096,
//			<!-- (0x08<<24) | (0x09<<16) | (0x0A<<8) | (0x06) --> 134810118,
//			<!-- (0x02<<24) | (0x12<<16) | (0x22<<8) | (0x21) --> 34742817,
//			<!-- (0x20<<24) | (0x24<<16) | (0x14<<8) | (0x04) --> 539235332,
//			<!-- (0x05<<24) | (0x01<<16) | (0x11<<8) | (0x10) --> 83955984
//			],
//		var byte = 3 - (i%4);
//		var shortCol = (colorArray[i/4] >> (byte*8));

		var shortCol = colorArray[i];
		var c0 = (shortCol & 0x003) * 5;			// 0x0, 0x5, 0xA, 0xF	
		var c1 = ((shortCol<<2) & 0x030) * 5;		// 0x00, 0x50, 0xA0, 0xF0
		var c2 = ((shortCol<<4) & 0x300) * 5;		// 0x000, 0x500, 0xA00, 0xF00
		return (c0 | ((c0|c1) << 4) | ((c1|c2) << 8) | (c2 << 12)); 
	}

//	(:m1plus)
//	function colorHexToIndex(col)
//	{
//		//var r = ((col>>20) & 0x0F) / 5;	// 0-3
//		//var g = ((col>>12) & 0x0F) / 5;	// 0-3
//		//var b = ((col>>4) & 0x0F) / 5;	// 0-3
//		
//		// 0x2A is half of 0x55 - we're basically rounding to nearest multiple of 0x55
//		var r = (((col>>16) & 0xFF) + 0x2A) / 0x55;	// 0-3
//		var g = (((col>>8) & 0xFF) + 0x2A) / 0x55;	// 0-3
//		var b = ((col & 0xFF) + 0x2A) / 0x55;	// 0-3
//		
//		var index = colorArray.indexOf((r<<4) | (g<<2) | b);
//		if (index < 0)
//		{
//			index = 0;
//		}
//	
////		var index = 0;
////		for (var i=0; i<64; i++)
////		{
////			if (shortTest == colorArray[i])
////			{
////				index = i;
////				break;
////			}
////		}
//		
//		return index;
//	}

	//const SECONDS_FIRST_CHAR_ID = 21;
	//const SECONDS_SIZE_HALF = 8;
	//!const SECONDS_CENTRE_OFFSET = SCREEN_CENTRE_X - SECONDS_SIZE_HALF;

	//enum
	//{
	//	SECONDFONT_TRI = 0,
	//	//!SECONDFONT_V = 1,
	//	//!SECONDFONT_LINE = 2,
	//	//!SECONDFONT_LINETHIN = 3,
	//	//!SECONDFONT_CIRCULAR = 4,
	//	//!SECONDFONT_CIRCULARTHIN = 5,
	//	SECONDFONT_TRI_IN = 6,
	//	//!SECONDFONT_V_IN = 7,
	//	//!SECONDFONT_LINE_IN = 8,
	//	//!SECONDFONT_LINETHIN_IN = 9,
	//	//!SECONDFONT_CIRCULAR_IN = 10,
	//	//!SECONDFONT_CIRCULARTHIN_IN = 11,
	//	SECONDFONT_UNUSED = 12
	//}

	//var secondsX = [120, 132, 143, 155, 166, 176, 186, 195, 203, 211, 217, 222, 227, 230, 231, 232, 231, 230, 227, 222, 217, 211, 203, 195, 186, 176, 166, 155, 143, 132, 120, 108, 97, 85, 74, 64, 54, 45, 37, 29, 23, 18, 13, 10, 9, 8, 9, 10, 13, 18, 23, 29, 37, 45, 54, 64, 74, 85, 97, 108, 120, 131, 142, 153, 164, 174, 183, 192, 200, 207, 214, 219, 223, 226, 227, 228, 227, 226, 223, 219, 214, 207, 200, 192, 183, 174, 164, 153, 142, 131, 120, 109, 98, 87, 76, 66, 57, 48, 40, 33, 26, 21, 17, 14, 13, 12, 13, 14, 17, 21, 26, 33, 40, 48, 57, 66, 76, 87, 98, 109]b;
	//var secondsY = [7, 8, 9, 12, 17, 22, 28, 36, 44, 53, 63, 73, 84, 96, 107, 119, 131, 142, 154, 165, 175, 185, 194, 202, 210, 216, 221, 226, 229, 230, 231, 230, 229, 226, 221, 216, 210, 202, 194, 185, 175, 165, 154, 142, 131, 119, 107, 96, 84, 73, 63, 53, 44, 36, 28, 22, 17, 12, 9, 8, 11, 12, 13, 16, 20, 25, 32, 39, 47, 56, 65, 75, 86, 97, 108, 119, 130, 141, 152, 163, 173, 182, 191, 199, 206, 213, 218, 222, 225, 226, 227, 226, 225, 222, 218, 213, 206, 199, 191, 182, 173, 163, 152, 141, 130, 119, 108, 97, 86, 75, 65, 56, 47, 39, 32, 25, 20, 16, 13, 12]b;
	var secondsX = new[60*2]b;
	var secondsY = new[60*2]b;
	//!const secondsString = "\u0015\u0016\u0017\u0018\u0019\u001a\u001b\u001c\u001d\u001e\u001f" +					// 11
	//	"\u0020\u0021\u0022\u0023\u0024\u0025\u0026\u0027\u0028\u0029\u002a\u002b\u002c\u002d\u002e\u002f" +		// 27
	//	"\u0030\u0031\u0032\u0033\u0034\u0035\u0036\u0037\u0038\u0039\u003a\u003b\u003c\u003d\u003e\u003f" +		// 43
	//	"\u0040\u0041\u0042\u0043\u0044\u0045\u0046\u0047\u0048\u0049\u004a\u004b\u004c\u004d\u004e\u004f" +		// 59
	//	"\u0050";																									// 60
	
	var secondsColorIndexArray = new[60]b;
	
	//const BUFFER_SIZE = 62;
	var bufferBitmap = null;
	var bufferIndex = -1;	// ensures buffer will get updated first time
	var bufferX;
	var bufferY;
	
	//const SCREEN_CENTRE_X = 120;
	//const SCREEN_CENTRE_Y = 120;
	//const OUTER_FIRST_CHAR_ID = 12;
	//const OUTER_SIZE_HALF = 8;
	//const OUTER_CENTRE_OFFSET = 117;

	var outerXY = new[120]b;
	
	//var characterString;

	//var circleFont;
	//var ringFont;

	//var worldBitmap;

	function getMinMax(v, min, max)
	{
		return (v<min) ? min : ((v>max) ? max : v);
	}

	function getNullCheckZero(v)
	{
		return ((v != null) ? v : 0);
	}

	//enum
	//{
	//	//!APPFONT_ULTRA_LIGHT = 0,
	//	//!APPFONT_EXTRA_LIGHT = 1,
	//	//!APPFONT_LIGHT = 2,
	//	APPFONT_REGULAR = 3,
	//	//!APPFONT_BOLD = 4,
	//	APPFONT_HEAVY = 5,			// our custom number fonts are assumed to be at the top of this enum
	//	
	//	APPFONT_ULTRA_LIGHT_TINY = 6,
	//	//!APPFONT_EXTRA_LIGHT_TINY = 7,
	//	//!APPFONT_LIGHT_TINY = 8,
	//	//!APPFONT_REGULAR_TINY = 9,
	//	//!APPFONT_BOLD_TINY = 10,
	//	//!APPFONT_HEAVY_TINY = 11,
	//	
	//	//!APPFONT_ULTRA_LIGHT_SMALL = 12,
	//	//!APPFONT_EXTRA_LIGHT_SMALL = 13,
	//	//!APPFONT_LIGHT_SMALL = 14,
	//	APPFONT_REGULAR_SMALL = 15,
	//	//!APPFONT_BOLD_SMALL = 16,
	//	//!APPFONT_HEAVY_SMALL = 17,
	//	
	//	//!APPFONT_ULTRA_LIGHT_MEDIUM = 18,
	//	//!APPFONT_EXTRA_LIGHT_MEDIUM = 19,
	//	//!APPFONT_LIGHT_MEDIUM = 20,
	//	//!APPFONT_REGULAR_MEDIUM = 21,
	//	//!APPFONT_BOLD_MEDIUM = 22,
	//	//!APPFONT_HEAVY_MEDIUM = 23,
	//
	//	APPFONT_SYSTEM_XTINY = 24,
	//	APPFONT_SYSTEM_TINY = 25,
	//	//!APPFONT_SYSTEM_SMALL = 26,
	//	//!APPFONT_SYSTEM_MEDIUM = 27,
	//	APPFONT_SYSTEM_LARGE = 28,
	//
	//	//!APPFONT_SYSTEM_NUMBER_NORMAL = 29,	// FONT_SYSTEM_NUMBER_MILD 
	//	//!APPFONT_SYSTEM_NUMBER_MEDIUM = 30,	// FONT_SYSTEM_NUMBER_MEDIUM 
	//	//!APPFONT_SYSTEM_NUMBER_LARGE = 31,		// FONT_SYSTEM_NUMBER_HOT 
	//	//!APPFONT_SYSTEM_NUMBER_HUGE = 32,		// FONT_SYSTEM_NUMBER_THAI_HOT 
	//
	//	APPFONT_NUMBER_OF_FONTS = 33
	//}

	// custom time font ascii characters:
	// 48-57 = 0-9
	// 58 = :
	//enum
	//{
	//	APPCHAR_0 = 48,		// digit 0
	//	APPCHAR_1 = 49,		// digit 1
	//	//!APPCHAR_2 = 50,		// digit 2
	//	//!APPCHAR_3 = 51,		// digit 3
	//	//!APPCHAR_4 = 52,		// digit 4
	//	//!APPCHAR_5 = 53,		// digit 5
	//	//!APPCHAR_6 = 54,		// digit 6
	//	//!APPCHAR_7 = 55,		// digit 7
	//	//!APPCHAR_8 = 56,		// digit 8
	//	APPCHAR_9 = 57,		// digit 9
	//	//!APPCHAR_COLON = 58,	// call this digit 10!
	//
	//	APPCHAR_A = 65,		// letter A
	//	APPCHAR_F = 70,		// letter F
	//
	//	APPCHAR_SPACE = 32,
	//	APPCHAR_COMMA = 44,
	//	APPCHAR_PLUS = 43,
	//	APPCHAR_MINUS = 45,
	//	//!APPCHAR_DOT = 46,
	//	//!APPCHAR_f = 102,
	//	APPCHAR_t = 116,
	//	//!APPCHAR_F = 70,
	//	APPCHAR_T = 84,
	//	APPCHAR_OPEN_SQUARE_BRACKET = 91,
	//	APPCHAR_CLOSE_SQUARE_BRACKET = 93,
	//}
	
	var kernTable;
	
	function getKern(cur, next, appFontCur, appFontNext, narrow)
	{
		var val = 0;
		
//		var kernTable = [		// 480 bytes of code to initialize (136 byte array)
//						/*76543210    3210 :98     :987654 */
//			/* 0 & 1 */	0x10F01010, 0x01010000, 0x04218104,
//			/* 2 & 3 */	0x10F20000, 0x10100100, 0x000010F0,
//			/* 4 & 5 */	0x30001020, 0x10100110, 0x011010F0,
//			/* 6 & 7 */	0x10F01010, 0x12400110, 0x020010F6,
//			/* 8 & 9 */	0x10F01010, 0x10100000, 0x000010F0,
//			/* :     */	0x00012140, 0x00000000,
//						/* NARROW / COLON */
//						/*76543210    3210 :98     :987654 */
//			/* 0 & 1 */	0x10000010, 0x00010000, 0x02217104,
//			/* 2 & 3 */	0x10020000, 0x00100000, 0x00001000,
//			/* 4 & 5 */	0x30102020, 0x00100030, 0x00201000,
//			/* 6 & 7 */	0x10000010, 0x12400010, 0x01001006,
//			/* 8 & 9 */	0x10000010, 0x00100000, 0x00001000,
//			/* :     */	0x00001020, 0x00000000,
//		];
	
		var bits = cur*48 + next*4;
		var byte4 = bits/32;
	
		// make sure index inside array
		if (byte4>=0 && byte4<17)
		{
			bits = bits%32;
			
			val = (kernTable[byte4 + (narrow?17:0)] >> bits) & 0xF;
			if (val > 0x8)
			{
				val -= 0x10;
			}
		}
		
//for (var i=0; i<6; i++)
//{
//	for (var j=0; j<2; j++)
//	{
//		cur = 1;		// 1 or 2
//		next = 4;
//		appFontCur = i;
//		narrow = (j==0);
//
//var tempVal1 = val;
	
		// special case code for different weights
		// saves 100 bytes compared to version below
		if (next==4 && (cur==1 || cur==2))
		{
			var adjust = ((((
			// cur==1	ultralight +2	extralight +2	light +1		regular 0		bold -1			heavy -2     
						(0x6l<<0) | 	(0x6l<<3) | 	(0x5l<<6) | 	(0x4l<<9) | 	(0x3l<<12) | 	(0x2l<<15) | 
			// cur==2	ultralight +1	extralight +1	light 0			regular 0		bold 0			heavy -1     
						(0x5l<<18) | 	(0x5l<<21) | 	(0x4l<<24) | 	(0x4l<<27) | 	(0x4l<<30) | 	(0x3l<<33) 
					) >> (appFontCur*3 + (cur-1)*18)) & 0x07) - 4).toNumber();	// make sure not still a long
					
			val += ((narrow && adjust>0) ? 0 : adjust);
		}

//var tempVal2 = val;
//val = tempVal1;
//
		// special case code for different weights
//		if (cur==1 && next==4)	// 1-4
//		{
//			if (appFontCur<=1/*APPFONT_EXTRA_LIGHT*/ && !narrow)
//			{
//				val += 2;
//			}
//			else if (appFontCur==2/*APPFONT_LIGHT*/ && !narrow)
//			{
//				val += 1;
//			}
//			else if (appFontCur==4/*APPFONT_BOLD*/)
//			{
//				val -= 1;
//			}
//			else if (appFontCur==5/*APPFONT_HEAVY*/)
//			{
//				val -= 2;
//			}
//		}
//		else if (cur==2 && next==4)	// 2-4
//		{
//			if (appFontCur<=1/*APPFONT_EXTRA_LIGHT*/ && !narrow)
//			{
//				val += 1;
//			}
//			else if (appFontCur==5/*APPFONT_HEAVY*/)
//			{
//				val -= 1;
//			}
//		}
	
//tempVal1 = val;
//if (tempVal1 != tempVal2)
//{
//	System.println("mismatch appFontCur=" + appFontCur + " narrow=" + narrow);
//}
//	
//	}
//}

		return val + (narrow?3:0);
	}
	
    var bitsSupported;

	function useUnsupportedFieldFont(s)
	{
//		var bits = [
//		//	0-31		32-63		64-95		96-127		128-159		160-191		192-223		224-255		256-287		288-319		320-351		352-383
//			0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000 
//		];
//
//		// all the chars in the custom field .fnt files
//		var chars = [
//			32,37,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,92,
//			193,196,197,199,201,204,205,211,214,216,218,219,220,221,260,268,282,317,321,323,336,344,346,352,377,381			 
//		];
//		
//		for (var i=0; i<chars.size(); i++)
//		{
//			var c = chars[i];
//			
//			var byte = c / 32;
//			var bit = c % 32;
//			
//			bits[byte] |= (0x1<<bit);  
//		}
//		
//		System.println("bits = " + bits.toString());
        
        //var bitsSupported = [0, 134213665, 402653182, 0, 0, 0, 1028141746, 0, 67112976, 536870912, 83951626, 570425345];
        var bitsSize = bitsSupported.size();
        
        var sArray = s.toUpper().toCharArray();		// upper case
        var sArraySize = sArray.size();
        for (var i=0; i<sArraySize; i++)
        {
        	var c = sArray[i].toNumber();	// unicode number
			var byte = c / 32;
			var bit = c % 32;
	       	//System.println("c=" + c + " byte=" + byte + " bit=" + bit);
			if (byte<0 || byte>=bitsSize || (bitsSupported[byte]&(0x1<<bit))==0)
			{
				return true;
			}
		}
				
		return false;
	}
	
	var myChars = new[78]b;

	function getMyCharDiacritic(c)
	{
		var diacritic = 700;
		var cNum = c.toNumber() - 190;
		if (cNum>0)		// only search array if it's a character with diacritic
		{
			// 650 bytes of code to initialize 52 values - so moved to jsonData instead
			//var c1 = [ 3,  6,  7,  9, 11, 14, 15, 21, 24,  26, 28, 29, 30, 31, 70, 78, 92, 127, 131, 133, 146, 154, 156, 162, 187, 191]b;		// -190
			//var c2 = [65, 65, 65, 67, 69, 73, 73, 79, 79, 216, 85, 85, 85, 89, 65, 67, 69,  76,  76,  78,  79,  82,  83,  83,  90,  90]b;
			//var c3 = [69, 70, 71, 72, 69, 73, 74, 69, 70,   0, 69, 75, 70, 69, 76, 77, 77,  78,  79,  69,  80,  77,  69,  77,  69,  77]b;		// -700
			
			for (var i=0; i<26; i++)
			{
				if (myChars[i] == cNum)
				{
					c = myChars[i+26].toChar();
					diacritic += myChars[i+52];
					break;
				}
			}
		}
		
		return [c, diacritic];
	}
	
	var parseIndex;
	
   	// find next comma or end of array
//	function parseToComma(charArray, charArraySize)
//	{	
//    	for (; parseIndex<charArraySize; parseIndex++)
//    	{
//    		if (charArray[parseIndex].toNumber()==44/*APPCHAR_COMMA*/)
//    		{
//    			break;
//    		}
//    	}
//    }
    	
	function parseSign(charArray, charArraySize)
	{
		if (parseIndex<charArraySize)
		{	
	   		var c = charArray[parseIndex].toNumber();
			if (c==45/*APPCHAR_MINUS*/)
			{
				parseIndex++;
				return -1;
			}
			else if (c==43/*APPCHAR_PLUS*/)
			{
				parseIndex++;
				// return 1; below
			}
		}
		
		return 1;
	}

	function parseNumber(charArray, charArraySize)
	{
		var v = 0;
		var vMult = 1;
    	var allowSkip = true;    	// skip over unknown characters before first numeric character or minus or comma
	
    	for (; parseIndex<charArraySize; parseIndex++)
    	{
    		var c = charArray[parseIndex].toNumber();
    		if (c>=48/*APPCHAR_0*/ && c<=57/*APPCHAR_9*/)
    		{
    			v = v*10 + (c-48/*APPCHAR_0*/);
    			allowSkip = false; 
    		}
    		else if (c==45/*APPCHAR_MINUS*/)
    		{
    			vMult = -1;
    			allowSkip = false; 
    		}
    		else if (c==44/*APPCHAR_COMMA*/ || !allowSkip)
    		{
    			break;
    		}
    	}

		return v*vMult;
	}

	// Parse (number separator number)
	function parseTwoNumbers(charArray, charArraySize)
	{
		var n = new[2];
		
		n[0] = parseNumber(charArray, charArraySize);

		// reached non-numeric character
		parseIndex++;		// step over the separator
		
		n[1] = parseNumber(charArray, charArraySize);
		
		//System.println("parseTwoNumbers=" + n[0] + " and " + n[1]);

		return n;
	}
	
//	function parseNumberComma(charArray, charArraySize)
//	{
//		var v = parseNumber(charArray, charArraySize);
//
//		parseToComma(charArray, charArraySize);   	// find next comma or end of array
//		parseIndex++;		// step over the comma
//
//		return v;
//	}

//	function parseBooleanComma(charArray, charArraySize)
//	{
//		var v = false;
//	
//		if (parseIndex<charArraySize)
//		{	
//    		var c = charArray[parseIndex].toNumber();
//			v = (c==116/*APPCHAR_t*/ || c==49/*APPCHAR_1*/ || c==84/*APPCHAR_T*/);
//				
//			parseToComma(charArray, charArraySize);   	// find next comma or end of array
//			parseIndex++;		// step over the comma
//		}
//
//		return v;
//	}

//	function parseStringComma(charArray, charArraySize)
//	{
//		var v = "";
//		
//		var charStart = parseIndex;
//		parseToComma(charArray, charArraySize);   	// find next comma or end of array
//		var charEnd = parseIndex;
//		parseIndex++;		// step over the comma
//		
//		if (charEnd > charStart)
//		{
//			var charMax = charStart+20;		// limit length of strings just in case
//			if (charEnd > charMax)
//			{
//				charEnd = charMax;
//			}
//			v = StringUtil.charArrayToString(charArray.slice(charStart, charEnd));	
//		}
//
//		return v;
//	}

	function propertiesGetBoolean(p)
	{
		// this test code for null works fine
		//var test1=null;
		//var test1=5;
		//var test1=1.754;
		//var test1="a";
		//var test2=(test1?1:2);
		//System.println("test2=" + test2);

		//return (applicationProperties.getValue(p) ? true : false);	got some crashes on real watch on this line? Error: Unexpected Type Error
		
		var v = applicationProperties.getValue(p);
		if ((v == null) || !(v instanceof Boolean))
		{
			v = false;
		}
		return v;
	}
	
	function propertiesGetNumber(p)
	{
		var v = applicationProperties.getValue(p);
		if ((v == null) || (v instanceof Boolean))
		{
			v = 0;
		}
		else if (!(v instanceof Number))
		{
			v = v.toNumber();
			if (v == null)
			{
				v = 0;
			}
		}
		return v;
	}
	
	function propertiesGetFloat(p)
	{
		var v = applicationProperties.getValue(p);
		if ((v == null) || (v instanceof Boolean) || (v instanceof Char) || (v instanceof Symbol))
		{
			v = 0.0;
		}
		else if (!(v instanceof Float))
		{
			v = v.toFloat();
			if (v == null)
			{
				v = 0.0;
			}
		}
		return v;
	}
	
	function propertiesGetString(p)
	{	
		var v = applicationProperties.getValue(p);
		if (v == null)
		{
			v = "";
		}
		else if (!(v instanceof String))
		{
			v = v.toString();
		}
		return v;
	}
	
	function propertiesGetCharArray(p)
	{	
		return propertiesGetString(p).toCharArray();
	}
	
	// Parse 2 numbers (number separator number) from a string
	function propertiesGetTwoNumbers(p)
	{
		var charArray = propertiesGetCharArray(p);
		var charArraySize = charArray.size();
		parseIndex = 0;
		
		return parseTwoNumbers(charArray, charArraySize);
	}
	
	// Parse a time (hours & minutes) from a string
	function propertiesGetTime(p)
	{
		var t = new[2];		// 0/1/2 for nothing/sunrise/sunset, then a time
		var adjust = 12*60;	// for sunrise/sunset add 12 hours to the time so we can store +-12 hours in a positive number

		// look for "sunrise" and "sunset" at the start
		var s = propertiesGetString(p).toUpper();
		if (s.find("SUNRISE")==0)
		{
			t[0] = 0x01/*PROFILE_START_SUNRISE*/;
			s = s.substring(7, s.length());
		}
		else if (s.find("SUNSET")==0)
		{
			t[0] = 0x02/*PROFILE_START_SUNSET*/;
			s = s.substring(6, s.length());
		}
		else
		{
			t[0] = 0;
			adjust = 0;
		}

		var charArray = s.toCharArray();
		var charArraySize = charArray.size();
		parseIndex = 0;
		
		var sign = parseSign(charArray, charArraySize);
		var n = parseTwoNumbers(charArray, charArraySize);

		t[1] = getMinMax(adjust + sign*(n[0]*60 + n[1]), 0, 24*60);		// convert hours to minutes and check in correct range

		return t;		
	}

	function addStringToCharArray(s, toArray, toLen, toMax)
	{
		var charArray = s.toCharArray();
		var charArraySize = charArray.size();
		
		if (toLen+charArraySize <= toMax)
		{ 
			for (var i=0; i<charArraySize; i++)
			{
				toArray[toLen] = charArray[i];
				toLen += 1;
			}
		}
	
		return toLen;
	}
	
	function addStringToCharArrayWithDiacritics(s, toArray, toLen, toMax)
	{
		var charArray = s.toCharArray();
		var charArraySize = charArray.size();
		
		if (toLen+(charArraySize*2) <= toMax)
		{ 
			for (var i=0; i<charArraySize; i++)
			{
				var c = getMyCharDiacritic(charArray[i]);

				toArray[toLen] = c[0];
				toArray[toLen + charArraySize] = ((c[1]>700) ? c[1].toChar() : 0);

				toLen += 1;
			}
		}
	
		return toLen;
	}
	
    // Order of calling on start up
	// initialize() → onLayout() → onShow() → onUpdate()
	//
	// Order of calling when settings changed
	// onSettingsChanged() → onUpdate()
	//
	// Order of calling on close
	// onHide()

    function initialize()
    {
        //System.println("initialize");
    }

//var timeStamp;

    // Load your resources here
    function onLayout(dc)
    {
        //System.println("onLayout");
//timeStamp = System.getTimer();

		//var storage = applicationStorage;
		//var fonts = Rez.Fonts;
		var watchUi = WatchUi;

		//if (forceClearStorage)
		//{
		//	storage.clearValues();		// clear all values from storage for debugging
		//}		
	
        var deviceSettings = System.getDeviceSettings();	// 960 bytes, but uses less code memory 
		hasDoNotDisturb = (deviceSettings has :doNotDisturb);
		hasLTE = (deviceSettings.connectionInfo[:lte]!=null);
		hasElevationHistory = SensorHistory has :getElevationHistory;
		hasPressureHistory = SensorHistory has :getPressureHistory;
		hasHeartRateHistory = SensorHistory has :getHeartRateHistory;

		// need to seed the random number generator?
		//var clockTime = System.getClockTime();
		//var seed = clockTime.sec + clockTime.min*60 + clockTime.hour*(60*60) + System.getTimer();
		//Math.srand(seed);
				
        //circleFont = WatchUi.loadResource(fonts.id_circle);
        //ringFont = WatchUi.loadResource(fonts.id_ring);

		//worldBitmap = WatchUi.loadResource(Rez.Drawables.id_world);

		// load in permanent global data
		{
			var dataResource = watchUi.loadResource(Rez.JsonData.id_data);
			kernTable = dataResource[0];
			bitsSupported = dataResource[1];
		}

//System.println("Timer json1=" + (System.getTimer()-timeStamp) + "ms");

        // If this device supports BufferedBitmap, allocate the buffer for what's behind the seconds indicator 
        //if (Toybox.Graphics has :BufferedBitmap)
		// This full color buffer is needed because anti-aliased fonts cannot be drawn into a buffer with a reduced color palette
        bufferBitmap = new Graphics.BufferedBitmap({:width=>62/*BUFFER_SIZE*/, :height=>62/*BUFFER_SIZE*/});
		
		// load in character string (for seconds & outer ring)
		//characterString = WatchUi.loadResource(Rez.JsonData.id_characterString);

		// load in data values which are stored as byte arrays (to save memory) 
		{
			var tempResource = watchUi.loadResource(Rez.JsonData.id_dataBytes);
			
			// second indicator & outer ring positions
			for (var i=0; i<120; i++)
			{
				secondsX[i] = tempResource[0][i];
				secondsY[i] = tempResource[1][i];
				outerXY[i] = tempResource[2][i];

				// table for characters with diacritics
				if (i<78)
				{
					myChars[i] = tempResource[3][i];

					if (i<64)
					{
						colorArray[i] = tempResource[4][i];

						if (i<36)
						{
							bufferValues[i] = tempResource[6][i];

							if (i<24)
							{
								outerValues[i] = tempResource[5][i];
							}
						}
					}
				}
			}
			
			tempResource = null;
		}

//System.println("Timer json2=" + (System.getTimer()-timeStamp) + "ms");

		var timeNowValue = Time.now().value();

		initHeartSamples(timeNowValue);

		// remember which profile was active and also any profileDelayEnd value
		loadMemoryData(timeNowValue);
		
//System.println("Timer loadmem=" + (System.getTimer()-timeStamp) + "ms");

		loadProfileData();		// load profile times
		
//System.println("Timer loadprof=" + (System.getTimer()-timeStamp) + "ms");
    }

	function saveDataForStop()
	{
		// remember the active profile and profileDelayEnd and other variables we want to save between runs
		saveMemoryData();
	}

	// called from the app when it is being ended
	function onStop()
	{
        //System.println("onStop");

		saveDataForStop();
	}

    // Called when this View is brought to the foreground.
    // Restore the state of this View and prepare it to be shown. This includes loading resources into memory.
    function onShow()
    {
        //System.println("onShow");

		/*
		// calculate second indicator positions & character string
		{
			//var secondsX = new[60*2];
			//var secondsY = new[60*2];

			for (var i=0; i<60; i++)
			{
        		var r = Math.toRadians(i*6);
        		var rSin = Math.sin(r);
        		var rCos = Math.cos(r);
        		var x;
        		var y;
	        	// top left of char
	        	x = Math.floor(SCREEN_CENTRE_X - SECONDS_SIZE_HALF + 0.5 + SECONDS_CENTRE_OFFSET * rSin);
	        	y = Math.floor(SCREEN_CENTRE_Y - SECONDS_SIZE_HALF + 0.5 - SECONDS_CENTRE_OFFSET * rCos) - 1;
		    	secondsX[i] = x.toNumber() + SECONDS_SIZE_HALF;	// make sure in range 0 to 255
		    	secondsY[i] = y.toNumber() + SECONDS_SIZE_HALF;	// make sure in range 0 to 255
	
				var i60 = i+60;
        		x = Math.floor(SCREEN_CENTRE_X - SECONDS_SIZE_HALF + 0.5 + (SECONDS_CENTRE_OFFSET-4) * rSin);
        		y = Math.floor(SCREEN_CENTRE_Y - SECONDS_SIZE_HALF + 0.5 - (SECONDS_CENTRE_OFFSET-4) * rCos) - 1;
		    	secondsX[i60] = x.toNumber() + SECONDS_SIZE_HALF;	// make sure in range 0 to 255
		    	secondsY[i60] = y.toNumber() + SECONDS_SIZE_HALF;	// make sure in range 0 to 255
			}
			
			//storage.setValue("secondsX", secondsX);
			//storage.setValue("secondsY", secondsY);
	    }
		*/
		
		/*
		// calculate outer ring positions & character string
		{
			//var outerX = new[120];
			//var outerY = new[120];

			for (var i=0; i<60; i++)
			{
		        var r = Math.toRadians((i*6) + 3.0);	// to centre of arc
	        	// top left of char
		    	var x = Math.floor(SCREEN_CENTRE_X - OUTER_SIZE_HALF + 0.5 + OUTER_CENTRE_OFFSET * Math.sin(r));
		    	var y = Math.floor(SCREEN_CENTRE_Y - OUTER_SIZE_HALF + 0.5 - OUTER_CENTRE_OFFSET * Math.cos(r)) - 1;
		    	outerXY[i*2] = x.toNumber() + OUTER_SIZE_HALF;	// make sure in range 0 to 255
		    	outerXY[i*2+1] = y.toNumber() + OUTER_SIZE_HALF;	// make sure in range 0 to 255
			}

			applicationStorage.setValue("outerXY", outerXY);
			//storage.setValue("outerY", outerY);
	    }
	    */
		
		/*
		// debug code for calculating font character positions of second indicator
        for (var i = 0; i < 60; i++)
        {
       		var id = SECONDS_FIRST_CHAR_ID + i;
			var page = (i % 2);		// even or odd pages
        
        	var r = Math.toRadians(i*6);

        	// top left of char
        	//var x = Math.floor(SCREEN_CENTRE_X - SECONDS_SIZE_HALF + 0.5 + SECONDS_CENTRE_OFFSET * Math.sin(r));
        	//var y = Math.floor(SCREEN_CENTRE_Y - SECONDS_SIZE_HALF + 0.5 - SECONDS_CENTRE_OFFSET * Math.cos(r));
        	var x = secondsX[i];
        	var y = secondsY[i] + 1;

        	var s = Lang.format("char id=$1$ x=$2$ y=$3$ width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=$4$ chnl=15", [id, x.format("%d"), y.format("%d"), page]);
        	System.println(s);
		}
		
		char id=21 x=112 y=0 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=22 x=124 y=1 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=23 x=135 y=2 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=24 x=147 y=5 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=25 x=158 y=10 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=26 x=168 y=15 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=27 x=178 y=21 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=28 x=187 y=29 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=29 x=195 y=37 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=30 x=203 y=46 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=31 x=209 y=56 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=32 x=214 y=66 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=33 x=219 y=77 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=34 x=222 y=89 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=35 x=223 y=100 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=36 x=224 y=112 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=37 x=223 y=124 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=38 x=222 y=135 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=39 x=219 y=147 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=40 x=214 y=158 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=41 x=209 y=168 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=42 x=203 y=178 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=43 x=195 y=187 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=44 x=187 y=195 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=45 x=178 y=203 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=46 x=168 y=209 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=47 x=158 y=214 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=48 x=147 y=219 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=49 x=135 y=222 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=50 x=124 y=223 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=51 x=112 y=224 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=52 x=100 y=223 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=53 x=89 y=222 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=54 x=77 y=219 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=55 x=66 y=214 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=56 x=56 y=209 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=57 x=46 y=203 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=58 x=37 y=195 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=59 x=29 y=187 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=60 x=21 y=178 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=61 x=15 y=168 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=62 x=10 y=158 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=63 x=5 y=147 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=64 x=2 y=135 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=65 x=1 y=124 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=66 x=0 y=112 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=67 x=1 y=100 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=68 x=2 y=89 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=69 x=5 y=77 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=70 x=10 y=66 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=71 x=15 y=56 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=72 x=21 y=46 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=73 x=29 y=37 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=74 x=37 y=29 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=75 x=46 y=21 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=76 x=56 y=15 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=77 x=66 y=10 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=78 x=77 y=5 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=79 x=89 y=2 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=80 x=100 y=1 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		*/
		
		/*
		// debug code for calculating font character positions of second indicator (moved in 4 pixels)
        for (var i = 0; i < 60; i++)
        {
       		var id = SECONDS_FIRST_CHAR_ID + i;
			var page = (i % 2);		// even or odd pages
        
        	var r = Math.toRadians(i*6);

        	// top left of char
        	//var x = Math.floor(SCREEN_CENTRE_X - SECONDS_SIZE_HALF + 0.5 + (SECONDS_CENTRE_OFFSET-4) * Math.sin(r));
        	//var y = Math.floor(SCREEN_CENTRE_Y - SECONDS_SIZE_HALF + 0.5 - (SECONDS_CENTRE_OFFSET-4) * Math.cos(r));
        	var x = secondsX[i+60];
        	var y = secondsY[i+60] + 1;

        	var s = Lang.format("char id=$1$ x=$2$ y=$3$ width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=$4$ chnl=15", [id, x.format("%d"), y.format("%d"), page]);
        	System.println(s);
		}

		char id=21 x=112 y=4 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=22 x=123 y=5 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=23 x=134 y=6 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=24 x=145 y=9 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=25 x=156 y=13 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=26 x=166 y=18 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=27 x=175 y=25 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=28 x=184 y=32 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=29 x=192 y=40 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=30 x=199 y=49 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=31 x=206 y=58 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=32 x=211 y=68 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=33 x=215 y=79 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=34 x=218 y=90 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=35 x=219 y=101 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=36 x=220 y=112 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=37 x=219 y=123 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=38 x=218 y=134 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=39 x=215 y=145 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=40 x=211 y=156 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=41 x=206 y=166 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=42 x=199 y=175 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=43 x=192 y=184 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=44 x=184 y=192 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=45 x=175 y=199 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=46 x=166 y=206 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=47 x=156 y=211 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=48 x=145 y=215 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=49 x=134 y=218 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=50 x=123 y=219 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=51 x=112 y=220 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=52 x=101 y=219 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=53 x=90 y=218 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=54 x=79 y=215 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=55 x=68 y=211 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=56 x=58 y=206 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=57 x=49 y=199 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=58 x=40 y=192 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=59 x=32 y=184 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=60 x=25 y=175 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=61 x=18 y=166 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=62 x=13 y=156 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=63 x=9 y=145 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=64 x=6 y=134 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=65 x=5 y=123 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=66 x=4 y=112 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=67 x=5 y=101 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=68 x=6 y=90 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=69 x=9 y=79 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=70 x=13 y=68 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=71 x=18 y=58 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=72 x=25 y=49 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=73 x=32 y=40 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=74 x=40 y=32 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=75 x=49 y=25 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=76 x=58 y=18 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=77 x=68 y=13 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=78 x=79 y=9 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=79 x=90 y=6 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=80 x=101 y=5 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		*/
		
		/*
		// debug code for calculating font character positions of outer circle
        for (var i = 0; i < 60; i++)
        {
       		var id = OUTER_FIRST_CHAR_ID + i;

			var page = (i % 2);		// even or odd pages
        
        	//var r = Math.toRadians((i*6) + 3.0);

        	// top left of char
        	//var x = Math.floor(SCREEN_CENTRE_X - OUTER_SIZE_HALF + 0.5 + OUTER_CENTRE_OFFSET * Math.sin(r));
        	//var y = Math.floor(SCREEN_CENTRE_Y - OUTER_SIZE_HALF + 0.5 - OUTER_CENTRE_OFFSET * Math.cos(r));
        	var x = outerXY[i*2].toNumber() - OUTER_SIZE_HALF;
        	var y = outerXY[i*2+1].toNumber() - OUTER_SIZE_HALF + 1;

        	var s = Lang.format("char id=$1$ x=$2$ y=$3$ width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=$4$ chnl=15", [id, x.format("%d"), y.format("%d"), page]);
        	System.println(s);
		}
		
		char id=12 x=118 y=-5 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=13 x=130 y=-4 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=14 x=142 y=-1 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=15 x=154 y=3 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=16 x=165 y=8 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=17 x=176 y=14 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=18 x=186 y=21 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=19 x=195 y=29 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=20 x=203 y=38 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=21 x=210 y=48 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=22 x=216 y=59 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=23 x=221 y=70 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=24 x=225 y=82 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=25 x=228 y=94 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=26 x=229 y=106 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=27 x=229 y=118 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=28 x=228 y=130 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=29 x=225 y=142 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=30 x=221 y=154 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=31 x=216 y=165 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=32 x=210 y=176 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=33 x=203 y=186 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=34 x=195 y=195 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=35 x=186 y=203 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=36 x=176 y=210 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=37 x=165 y=216 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=38 x=154 y=221 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=39 x=142 y=225 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=40 x=130 y=228 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=41 x=118 y=229 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=42 x=106 y=229 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=43 x=94 y=228 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=44 x=82 y=225 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=45 x=70 y=221 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=46 x=59 y=216 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=47 x=48 y=210 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=48 x=38 y=203 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=49 x=29 y=195 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=50 x=21 y=186 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=51 x=14 y=176 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=52 x=8 y=165 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=53 x=3 y=154 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=54 x=-1 y=142 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=55 x=-4 y=130 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=56 x=-5 y=118 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=57 x=-5 y=106 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=58 x=-4 y=94 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=59 x=-1 y=82 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=60 x=3 y=70 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=61 x=8 y=59 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=62 x=14 y=48 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=63 x=21 y=38 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=64 x=29 y=29 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=65 x=38 y=21 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=66 x=48 y=14 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=67 x=59 y=8 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=68 x=70 y=3 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=69 x=82 y=-1 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		char id=70 x=94 y=-4 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=0 chnl=15
		char id=71 x=106 y=-5 width=16 height=16 xoffset=0 yoffset=0 xadvance=16 page=1 chnl=15
		*/
    }

    // Called when this View is removed from the screen (including the app ending).
    // Save the state of this View here. This includes freeing resources from memory.
    function onHide()
    {
        //System.println("onHide");
	}

    // The user has just looked at their watch. Timers and animations may be started here.
    (:m2face)
    function onExitSleep()
    {
        //System.println("Glance");
        glanceActive = true;
        //WatchUi.requestUpdate();
    }

    // Terminate any active timers and prepare for slow updates.
    (:m2face)
    function onEnterSleep()
    {
        //System.println("Sleep");
        glanceActive = false;			// on only
        WatchUi.requestUpdate();
    }

	// Called by app when settings are changed by user
    function onSettingsChanged()
    {
    	settingsHaveChanged = true;		// set flag so onUpdate can handle this
    	
    	// when sending new settings it seems some memory gets allocated (by the system) between here and next onUpdate
    	// so release all the dynamic font resources here, so the system allocation isn't allocated after them
		releaseDynamicResources();

        WatchUi.requestUpdate();
	}
	
    (:m2face)
	function getSettingsForFaceOrApp()
	{
		honestyCheckbox = propertiesGetBoolean("H");
	
		demoProfilesOn = propertiesGetBoolean("DP");

		var n = propertiesGetTwoNumbers("DR");
		demoProfilesFirst = ((n[0]<1) ? 1 : n[0]) - 1;	// convert from user to code index
		demoProfilesLast = ((n[1]>(PROFILE_NUM_USER+PROFILE_NUM_PRESET)) ? (PROFILE_NUM_USER+PROFILE_NUM_PRESET) : n[1]) - 1;	// convert from user to code index

		propSunAltitudeAdjust = propertiesGetBoolean("SA");
		propNonActiveCalories = propertiesGetNumber("NC");
	}
	
    (:m2app)
	function getSettingsForFaceOrApp()
	{
	}
	
	function getPresetProfileString(profileIndex)
	{
		var jsonData = Rez.JsonData;
		var loadPreset = [jsonData.id_preset0, jsonData.id_preset1, jsonData.id_preset2, jsonData.id_preset3, jsonData.id_preset4, jsonData.id_preset5, jsonData.id_preset6, jsonData.id_preset7, jsonData.id_preset8, jsonData.id_preset9, jsonData.id_preset10, jsonData.id_preset11, jsonData.id_preset12, jsonData.id_preset13, jsonData.id_preset14, jsonData.id_preset15, jsonData.id_preset16];
		return WatchUi.loadResource(loadPreset[profileIndex - PROFILE_NUM_USER]);
	}

	function getProfileString(profileIndex)
	{
		return ((profileIndex<PROFILE_NUM_USER) ? applicationStorage.getValue("P" + profileIndex) : getPresetProfileString(profileIndex));
	}
	
	function profileTimeString(t, isSunrise, isSunset)
	{
		var s = "";
	
		if (isSunrise || isSunset)
		{
			t -= 12*60;	// remove 12 hours added to make positive for storage
			s = (isSunrise ? "Sunrise" : "Sunset");
			if (t>=0)
			{
				s += "+";
			}
			else
			{
				s += "-";
				t = -t;
			}
		}
		
		var hours = t/60;
		var minutes = t%60;
	
		s += hours.format("%02d") + ":" + minutes.format("%02d");
	
		return s;
	}

	(:m2face)		
	function setProfilePropertiesFaceOrApp(profileIndex)
	{
		if (profileIndex>=0 && profileIndex<PROFILE_NUM_USER)	// not for private or preset profiles
		{
			// set the profile properties from our profile times array			
			var days = profileData[profileIndex*6 + 2];		
			var daysNumber = 0;
			for (var i=0; i<7; i++)
			{
				if ((days&(0x1<<i))!=0)
				{
					daysNumber *= 10;
					daysNumber += i+1;
				}
			}
			applicationProperties.setValue("PD", daysNumber);
	
			var startTime = profileData[profileIndex*6 + 0];
			var endTime = profileData[profileIndex*6 + 1];
			var profileFlags = profileData[profileIndex*6 + 3];
			applicationProperties.setValue("PS", profileTimeString(startTime, (profileFlags&0x01/*PROFILE_START_SUNRISE*/)!=0, (profileFlags&0x02/*PROFILE_START_SUNSET*/)!=0));
			applicationProperties.setValue("PE", profileTimeString(endTime, (profileFlags&0x04/*PROFILE_END_SUNRISE*/)!=0, (profileFlags&0x08/*PROFILE_END_SUNSET*/)!=0));

			applicationProperties.setValue("35", (profileData[profileIndex*6 + 5] >= 0) ? (profileData[profileIndex*6 + 5] + 1) : "");		// glance profile

			applicationProperties.setValue("PB", ((profileFlags&0x10/*PROFILE_BLOCK_MASK*/)!=0));
			applicationProperties.setValue("PR", profileData[profileIndex*6 + 4]);		
		}
	}

	(:m2face)		
	function getProfileDataFromPropertiesFaceOrApp(profileIndex)
	{
		if (profileIndex>=0 && profileIndex<PROFILE_NUM_USER)	// not for private or preset profiles
		{
			// calculate activate times from properties
			var days = 0;
			var daysNumber = propertiesGetNumber("PD");
			while (daysNumber>0)
			{
				var d = daysNumber%10;
				daysNumber /= 10;
				
				if (d>=1 && d<=7)
				{
					days |= (0x1<<(d-1));					
				}
			}
			profileData[profileIndex*6 + 2] = days;

			var startTime = propertiesGetTime("PS");
			var endTime = propertiesGetTime("PE");
			profileData[profileIndex*6 + 0] = startTime[1];		// start time
			profileData[profileIndex*6 + 1] = endTime[1];		// end time
			
			profileData[profileIndex*6 + 5] = propertiesGetNumber("35") - 1;	// glance profile

			var profileFlags = ((startTime[0] & 0x03) | ((endTime[0] & 0x03) << 2));
			if (propertiesGetBoolean("PB"))
			{
				profileFlags |= 0x10/*PROFILE_BLOCK_MASK*/;
			}
			profileData[profileIndex*6 + 3] = profileFlags;

			profileData[profileIndex*6 + 4] = getMinMax(propertiesGetNumber("PR"), 0, 0xFF/*PROFILE_EVENTS_MASK*/);
		}
	}
	
	(:m2app)		
	function setProfilePropertiesFaceOrApp(profileIndex)
	{
	}
	
	(:m2app)		
	function getProfileDataFromPropertiesFaceOrApp(profileIndex)
	{
	}
	
	function handleSettingsChanged(second)
	{
		var demoProfilesOnPrev = demoProfilesOn;

		getSettingsForFaceOrApp();

		var profileManagement = propertiesGetNumber("PM");
		var profileNumber = propertiesGetNumber("PN") - 1;

		if (profileManagement == 0)				// current profile
		{
			if (demoProfilesOn!=demoProfilesOnPrev)		// special case for handling when demoProfiles is toggled from off to on - don't do any profile delay
			{
				profileDelayEnd = 0;
			}

			applicationProperties.setValue("PN", profileActive+1);		// set the profile number

			getProfileDataFromPropertiesFaceOrApp(profileActive);
			saveProfileData();		// remember new values
		}
		else
		{
			applicationProperties.setValue("PM", 0);

			if (profileManagement == 1)			// load from profile
			{
				if (profileNumber>=0 && profileNumber<(PROFILE_NUM_USER+PROFILE_NUM_PRESET))
				{
					var s = getProfileString(profileNumber);
					if (s!=null && (s instanceof String))
					{
						applicationProperties.setValue("EP", s);
					}

					setProfilePropertiesFaceOrApp(profileNumber);
				}
			}
			else if (profileManagement == 2)	// save to profile
			{
				if (profileNumber>=0 && profileNumber<PROFILE_NUM_USER)
				{
					var s = propertiesGetString("EP");
					applicationStorage.setValue("P" + profileNumber, s);

					getProfileDataFromPropertiesFaceOrApp(profileNumber);
					saveProfileData();		// remember new values
				}
			}

			profileDelayEnd = updateTimeNowValue + ((60-second)%60) + 2*60;		// delay of 2 minutes before any auto profile switching
			profileRandomEnd = 0;							// clear this
			demoProfilesCurrentEnd = 0;
		}
		
		profileActive = profileNumber;		// set the active profile number
	}
		
//	// forceChange is set to true when either the settings have been changed by the user or a new profile has loaded
//	// - in these situations if any of the demo settings flags are set then we need to set the relevant properties straight away
//	function checkDemoSettings(index, forceChange)
//	{
//		var changed = false;
//        
//        if (propDemoFontStylesOn /*|| forceDemoFontStyles*/)		// demo font styles on
//        {
//	        if ((index%3)==0 || forceChange)
//	        { 
//	        	var index3 = index/3;
//	        
//				propTimeHourFont = ((index3/6)%6);		// time hour font
//				propTimeMinuteFont = (index3%6);			// time minute font
//				propTimeItalic = (((index3/36)%2)==1); // && (propTimeHourFont<=5/*APPFONT_HEAVY*/) && (propTimeMinuteFont<=5/*APPFONT_HEAVY*/));		// italic
//		
//		    	propFieldFont = (6/*APPFONT_ULTRA_LIGHT_TINY*/ + (6*(index3%3)) + ((index3/3)%6));		// field font & weight
//		
//		    	changed = true;
//		    }
//		}
//			    
//        if (propDemoSecondStylesOn)		// demo second styles on
//        {
//	        if ((index%3)==0 || forceChange)
//	        { 
//		    	propSecondIndicatorStyle = ((index/3)%6/*SECONDFONT_TRI_IN*/) + (propSecondMoveInABit ? 6/*SECONDFONT_TRI_IN*/ : 0);		// second indicator style - cycles every 18
//		
//		    	changed = true;
//		    }
//
//			// 0, 1, 2, 3 -> 2/*REFRESH_ALTERNATE_MINUTES*/
//			// 4, 5, 6, 7 -> 0/*REFRESH_EVERY_SECOND*/
//			// 8, 9, 10 -> 1/*REFRESH_EVERY_MINUTE*/
//        	// prime number to be out of sync with indicator style
//			propSecondRefreshStyle = (((index%11)/4 + 2)%3);		// second refresh style
//
////        	var srs = index%11;		// prime number to be out of sync with indicator style
////        	if (srs<3)		// 0, 1, 2
////        	{
////        		srs = 1/*REFRESH_EVERY_MINUTE*/;
////        	}
////        	else if (srs<7)	// 3, 4, 5, 6
////        	{
////        		srs = 2/*REFRESH_ALTERNATE_MINUTES*/;
////        	}
////        	else			// 7, 8, 9, 10
////        	{
////        		srs = 0/*REFRESH_EVERY_SECOND*/;
////        	}
////	    	properties.setValue("12", srs);		// second refresh style
//	    	//changed = true;	don't need to set changed for this
//		}
//			    
//	    return changed;
//	}
	
    function formatHourForDisplayString(h, is24Hour, addLeadingZero)
    {
        // 12 or 24 hour, and check for adding a leading zero
        return (is24Hour ? h : (((h+11)%12) + 1)).format(addLeadingZero ? "%02d" : "%d"); 
    }
    
    function getVisibilityStatus(visibilityStatus, eVisible, dateInfoShort)
    {
    	if (visibilityStatus[eVisible]==null)
    	{
	    	if (eVisible==21/*STATUS_SUNEVENT_RISE*/ || eVisible==22/*STATUS_SUNEVENT_SET*/)
	    	{
    			calculateSun(dateInfoShort);
				if (sunTimes[7]!=null)
				{
    				visibilityStatus[eVisible] = ((eVisible==21/*STATUS_SUNEVENT_RISE*/) ? sunTimes[7] : !sunTimes[7]);
    			}
	    	}
    	}
    	
    	return (visibilityStatus[eVisible]!=null && visibilityStatus[eVisible]);
    }
    
//    function printMem(s)
//    {
//    	var stats = System.getSystemStats();
//		System.println("free=" + stats.freeMemory + " " + s);
//    }
    
    // Update the view
    function onUpdate(dc)
    {
		//System.println("onUpdate");
//var showTimer = firstUpdateSinceInitialize; 
//if (showTimer)
//{
//	System.println("Timer start=" + (System.getTimer()-timeStamp) + "ms");
//}
    
        var clockTime = System.getClockTime();	// get as first thing so we know it is correct and won't change later on
		var timeNow = Time.now();
		// don't do anything with gregorian.info time formatting up here - as the returned data could allocate different amounts of memory each time
        var hour = clockTime.hour;
        var minute = clockTime.min;
        var second = clockTime.sec;
		updateTimeNowValue = timeNow.value();
		updateTimeTodayValue = Time.today().value();
		updateTimeZoneOffset = clockTime.timeZoneOffset;
		var profileToActivate;
		var doLoadDynamicResources = false;

        //View.onUpdate(dc);        // Call the parent onUpdate function to redraw the layout

        //if (minute == updateLastMin && second == updateLastSec)
        //{
        //	//System.println("multiple onUpdate");
        //	return;
        //}
		//
		//if ((onOrGlanceActive&ITEM_ONGLANCE)==0)		// if not during glance
		//{        
	    //    updateLastSec = second;
	    //    updateLastMin = minute;
	    //}
	    
		//System.println("update rest sec=" + second);

		if (settingsHaveChanged || firstUpdateSinceInitialize)
		{		
			settingsHaveChanged = false;
			firstUpdateSinceInitialize = false;

			profileRandomLastMin = minute;	// don't do a random profile change on first minute (after initialize or settings change)
			profileGlance = -1;				// clear any glance stuff too
			profileGlanceReturn = 0;

			releaseDynamicResources();						// also done in onSettingsChanged()
			doLoadDynamicResources = true;
			
			handleSettingsChanged(second);		// save/load/export/import etc

//if (showTimer)
//{
//	System.println("Timer changed=" + (System.getTimer()-timeStamp) + "ms");
//}
		}
		
		profileToActivate = checkProfileToActivate(timeNow);
		if (profileToActivate != profileActive)
		{
			//System.println("profileToActivate=" + profileToActivate);
			
			releaseDynamicResources();
			doLoadDynamicResources = true;

			// copy saved profile string from storage to properties
			var s = getProfileString(profileToActivate);
			if (s!=null && (s instanceof String))
			{
				applicationProperties.setValue("EP", s);
			}
			
			applicationProperties.setValue("PN", profileToActivate+1);		// set the profile number

			setProfilePropertiesFaceOrApp(profileToActivate);

//if (showTimer)
//{
//	System.println("Timer activate=" + (System.getTimer()-timeStamp) + "ms");
//}
		}

		if (checkReloadDynamicResources())
		{
			releaseDynamicResources();
			doLoadDynamicResources = true;
		}

        if (doLoadDynamicResources)
        {
			var charArray = propertiesGetCharArray("EP");		// get the profile string "EP"
			gfxFromCharArray(charArray);			// load gfx from that

			gfxLoadDynamicResources();
//if (showTimer)
//{
//	System.println("Timer load0=" + (System.getTimer()-timeStamp) + "ms");
//}
			loadDynamicResources();

//if (showTimer)
//{
//	System.println("Timer load=" + (System.getTimer()-timeStamp) + "ms");
//}

//			System.println("gfxNum=" + gfxNum + " [512]");
//			System.println("dynResNum=" + dynResNum + " [16]");
        }
        
        //System.println("onUpdate sec=" + second);

	    //dc.drawBitmap(0, 0, worldBitmap);

		// test draw a circle
        //dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        //dc.drawText(0, -1, circleFont, "0", Graphics.TEXT_JUSTIFY_LEFT);
        
		// test draw a ring
        //dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        //dc.drawText(120, 120+75, ringFont, "0", Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);

        // test draw an icon
        //dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        //dc.drawText(60, 120 - 64 - 12, iconsFontResource, "A", Graphics.TEXT_JUSTIFY_CENTER);
        //dc.drawText(120, 120 + 64 - 12, iconsFontResource, "AAAAAAAA", Graphics.TEXT_JUSTIFY_CENTER);

		// test drawing a circle 
   		//dc.setColor(Graphics.COLOR_WHITE, backgroundColor);
		//dc.setPenWidth(4);		  
		//dc.drawCircle(120, 120 + 74, 25);		  

		// check for position every onUpdate - this is so we can get and store a position from the latest activity
		// (even if that position isn't currently being used by anything)
		calculatePosition();

		// sample the heart rate every time
		sampleHeartRate(second, false);
		heartChartVisible = false;		// until know otherwise

		//System.println("hour=" + gregorian.info(timeNow, Time.FORMAT_SHORT).hour + " utc=" + gregorian.utcInfo(timeNow, Time.FORMAT_SHORT).hour);
		// does not change with time simulation in simulator:
		//System.println("hour2=" + gregorian.info(Time.getCurrentTime(null), Time.FORMAT_SHORT).hour + " utc2=" + gregorian.utcInfo(Time.getCurrentTime(null), Time.FORMAT_SHORT).hour);
        
		gfxOnUpdate(dc, clockTime, timeNow);

		// draw the background to main display
        drawBackgroundToDc(dc);

        lastPartialUpdateSec = second;
		bufferIndex = -1;		// clear any background buffer being known

		// draw the seconds indicator to the screen
		if (propSecondIndicatorOn)
		{
        	if (propSecondRefreshStyle==0/*REFRESH_EVERY_SECOND*/)
        	{
    			drawSecond(dc, second, second);
    		}
    		else if ((propSecondRefreshStyle==1/*REFRESH_EVERY_MINUTE*/) ||
    			(propSecondRefreshStyle==2/*REFRESH_ALTERNATE_MINUTES*/ && (minute%2)==0))
    		{
    			// draw all the seconds up to this point in the minute
   				drawSecond(dc, 0, second);
    		}
    		else if (propSecondRefreshStyle==2/*REFRESH_ALTERNATE_MINUTES*/ && (minute%2)==1)
			{
				// always draw indicator at 0 in this mode
				// (it covers up frame slowdown when drawing all the rest of the seconds coming next ...)
   				drawSecond(dc, 0, 0);

    			// draw all the seconds after this point in the minute
   				drawSecond(dc, second+1, 59);
    		}
		}
    }

//	<!-- outer ring values (outerBigXY, outerOffscreenStart, outerOffscreenEnd) -->
//	[118, -3, 200, 33, 200, 117, 118, 199, 34, 199, -2, 117, -2, 33, 34, -3],
//	[  -2,   7,  19,  28,  37,  49,  58,  67,  79,  88,  97, 109 ],
//	[   9,  22,  30,  39,  52,  59,  69,  82,  89,  99, 112, 120 ],
//	var outerBigXY;
//	var outerOffscreenStart;
//	var outerOffscreenEnd;
	var outerValues = new[24]b;

	function drawBackgroundToDc(useDc)
	{ 
		var graphics = Graphics;
	
		var dcX;
		var dcY;

		var toBuffer = (useDc==null);
		if (toBuffer)	// offscreen buffer
		{
			//if (bufferBitmap==null)
			//{
			//	return;
			//}
		
			useDc = bufferBitmap.getDc();
			dcX = bufferX;
			dcY = bufferY;
		}
		else
		{
			dcX = 0;
			dcY = 0;
		}

		var dcWidth = useDc.getWidth();
		var dcHeight = useDc.getHeight();

    	// reset to the background color
		useDc.clearClip();
	    useDc.setColor(-1/*COLOR_TRANSPARENT*/, propBackgroundColor);
		// test draw background of offscreen buffer in a different color
		//if (toBuffer)
		//{
	    //	useDc.setColor(-1/*COLOR_TRANSPARENT*/, getColor64(4+42+(bufferIndex*4)%12));
		//}
        useDc.clear();
		
		gfxDrawBackground(useDc, dcX, dcY, toBuffer);

//		if (propDemoDisplayOn)
//		{
////	   		useDc.setColor(propTimeHourColor, -1/*COLOR_TRANSPARENT*/);
////	   		if (fontTimeHourResource!=null)		// sometimes onPartialUpdate is called between onSettingsChanged and onUpdate - so this resource could be null
////	   		{
////				useDc.drawText(120 - dcX, 120 - 105 - dcY, fontTimeHourResource, "012", graphics.TEXT_JUSTIFY_CENTER);
////				useDc.drawText(120 - dcX, 120 - 35 - dcY, fontTimeHourResource, "3456", graphics.TEXT_JUSTIFY_CENTER);
////				useDc.drawText(120 - dcX, 120 + 35 - dcY, fontTimeHourResource, "789:", graphics.TEXT_JUSTIFY_CENTER);
////			}
//
////	   		useDc.setColor(propTimeHourColor, -1/*COLOR_TRANSPARENT*/);
////	   		if (fontFieldResource!=null)		// sometimes onPartialUpdate is called between onSettingsChanged and onUpdate - so this resource could be null
////	   		{
////				//useDc.drawText(120 - dcX, 120 - 120 - dcY, fontFieldResource, " I:I1%", graphics.TEXT_JUSTIFY_CENTER);
////				//useDc.drawText(120 - dcX, 120 - 95 - dcY, fontFieldResource, "2345678", graphics.TEXT_JUSTIFY_CENTER);
////				//useDc.drawText(120 - dcX, 120 - 70 - dcY, fontFieldResource, "9-0\\/A.B,CD", graphics.TEXT_JUSTIFY_CENTER);
////				//useDc.drawText(120 - dcX, 120 - 45 - dcY, fontFieldResource, "EFGHIJKLMNO", graphics.TEXT_JUSTIFY_CENTER);
////				//useDc.drawText(120 - dcX, 120 - 20 - dcY, fontFieldResource, "PQRSTUVWXYZ", graphics.TEXT_JUSTIFY_CENTER);
////				//useDc.drawText(120 - dcX, 120 + 10 - dcY, fontFieldResource, "ÁÚÄÅÇÉÌÍÓÖØ", graphics.TEXT_JUSTIFY_CENTER);
////				//useDc.drawText(120 - dcX, 120 + 40 - dcY, fontFieldResource, "ÛÜÝĄČĚĽŁŃ", graphics.TEXT_JUSTIFY_CENTER);
////				//useDc.drawText(120 - dcX, 120 + 70 - dcY, fontFieldResource, "ŐŘŚŠŹŽ​", graphics.TEXT_JUSTIFY_CENTER);
////
////	   			var yOffsets = [-120, -95, -70, -45, -20, 10, 40, 70];
////	   			var sArray = [" I:I1%", "2345678", "9-0\\/A.B,CD", "EFGHIJKLMNO", "PQRSTUVWXYZ", "ÁÚÄÅÇÉÌÍÓÖØ", "ÛÜÝĄČĚĽŁŃ", "ŐŘŚŠŹŽ​"];
////
////				for (var i=0; i<sArray.size(); i++)
////				{
////					var charArray = sArray[i].toCharArray();
////					
////					// calculate total width first
////					var totalWidth = 0;
////					for (var j=0; j<charArray.size(); j++)
////					{
////						var c = getMyCharDiacritic(charArray[j]);
////	        			totalWidth += useDc.getTextWidthInPixels(c[0].toString(), fontFieldResource);
////					}
////					
////					// draw each character + any diacritic
////					var xOffset = 0;
////					for (var j=0; j<charArray.size(); j++)
////					{
////						var c = getMyCharDiacritic(charArray[j]);						
////						useDc.drawText(120 - dcX - totalWidth/2 + xOffset, 120 - dcY + yOffsets[i], fontFieldResource, c[0].toString(), 2/*TEXT_JUSTIFY_LEFT*/);
////		    			if (c[1]>700)
////		    			{
////							useDc.drawText(120 - dcX - totalWidth/2 + xOffset, 120 - dcY + yOffsets[i], fontFieldResource, c[1].toChar().toString(), 2/*TEXT_JUSTIFY_LEFT*/);
////		    			}
////						xOffset += useDc.getTextWidthInPixels(c[0].toString(), fontFieldResource);
////					}
////				}
////			}
// 
// 			// draw demo grid of all colors
//			for (var i=-3; i<3; i++)
//			{
//				var y = 130 + i * 20 - dcY;
//				if (y<=dcHeight && (y+20)>=0)
//				{
//					for (var j=-5; j<5; j++)
//					{
//						var x = 120 + j * 20 - dcX;
//						if (x<=dcWidth && (x+20)>=0)
//						{
//				   			useDc.setColor(getColor64(4 + (i+3) + (j+5)*6), -1/*COLOR_TRANSPARENT*/);
//							useDc.drawText(x, y, iconsFontResource, "F", 2/*TEXT_JUSTIFY_LEFT*/);	// solid squares
//						}
//					}
//				}
//			}
//
//			// draw demo grid of all shapes & icons
//	   		useDc.setColor(propTimeHourColor, -1/*COLOR_TRANSPARENT*/);
//
//			var x = 120 - dcX;
//			var y;
//			
//			var iconStrings = ["ACEGKI", "BDFHLJ", "NMPOYWRS", "QTVX", "[Z\\]^_`aU"];		// 60 code bytes to initialise
//			//var iconOffsets = [180, 200, 40, 20];		// 60 code bytes to initialise
//				
//			for (var i=0; i<5; i++)
//			{
//				//y = iconOffsets[i] - dcY;
//				y = (((0xBEl | (0xD2l<<8) | (0x1El<<16) | (0x0Al<<24) | (0x32l<<32))>>(i*8))&0xFF) - dcY;
//				if (y<=dcHeight && (y+20)>=0)
//				{
//					useDc.drawText(x, y, iconsFontResource, iconStrings[i], 1/*TEXT_JUSTIFY_CENTER*/);
//				}
//			}
//		}
	}

//	<!-- seconds buffer values (bufferSeconds, bufferPosX, bufferPosY) -->
//	[   0,   5,  11,  15,  20,  26,  30,  35,  41,  45,  50,  56 ],
//	[ 112, 166, 211, 211, 166, 120,  66,  12, -33, -33,  12,  59 ],
//	[ -33,  12,  59, 111, 165, 210, 210, 165, 120,  65,  12, -33 ]
//    var bufferSeconds;
//    var bufferPosX;
//    var bufferPosY;
    var bufferValues = new[36]b;

    (:m2face)
	function drawBuffer(secondsIndex, dc)
	{
						  	// t2   tr   r1   r2   br   b1   b2   bl   l1   l2   tl   t1
	    //var bufferSeconds = [   0,   5,  11,  15,  20,  26,  30,  35,  41,  45,  50,  56 ];
	    
	    var doUpdate = (bufferIndex < 0);	// if no buffer yet
	    
	    if (!doUpdate)
	    {
			// see if need to redraw the offscreen buffer (if clearIndex is outside it)
			var bufferSecondsStart = bufferValues[bufferIndex];						// current start of range in offscreen buffer
	    	var bufferNext = (bufferIndex + 1)%12;
		    var bufferSecondsNextMinusOne = (bufferValues[bufferNext] + 59)%60;		// current end of range in offscreen buffer - do it this way to handle when end is 0

			doUpdate = (secondsIndex<bufferSecondsStart || secondsIndex>bufferSecondsNextMinusOne);		// outside current range
		}

	    if (doUpdate)
	    {
			// find buffer which contains the indicator for specified second
			var useIndex = -1;
			for (var i=12-1; i>=0; i--)
			{
				if (secondsIndex>=bufferValues[i])
				{
					useIndex = i;
					break;
				}
			}
			
			if (useIndex>=0)
			{
								  	// t2   tr   r1   r2   br   b1   b2   bl   l1   l2   tl   t1
			    //var bufferPosX =    [ 112, 166, 211, 211, 166, 120,  66,  12, -33, -33,  12,  59 ];
			    //var bufferPosY =    [ -33,  12,  59, 111, 165, 210, 210, 165, 120,  65,  12, -33 ];		// 160 bytes of code to initialize

				bufferIndex = useIndex;		// set the buffer we are using
				bufferX = bufferValues[useIndex + 12] - 40;
				bufferY = bufferValues[useIndex + 24] - 40;
				
				drawBackgroundToDc(null);
	
				// test draw the offscreen buffer to see what is in it
		    	//dc.setClip(bufferX, bufferY, 62/*BUFFER_SIZE*/, 62/*BUFFER_SIZE*/);
				//dc.drawBitmap(bufferX, bufferY, bufferBitmap);
		    	//dc.clearClip();
			}
		}
	}

// timing of onUpdate from onPartialUpdate
//    	onUpdate(dc);
//    	return;
//
// normal
// total = 249000
// execution = 130000
// graphics = 70000
// display = 49920
//
// not drawing background or seconds
// total = 38093
// execution = 38093
// graphics = 0
// display = 0
//
// drawing background (to main dc only), not seconds
// total = 227000 (+189k)
// execution = 115000 (+77k)
// graphics = 61000 (+61k)
// display = 49920
// drawing background (to main dc only), not seconds - now down to:
// total = 176558 (-50k)
// execution = 58943 (-57k)
// graphics = 67695 (+7k)
// display = 49920
//
// drawing background (to main dc only) and all 60 seconds
// total = 309000 (+82k)
// execution = 176000 (+61k)
// graphics = 83000 (+22k)
// display = 49920
//
// drawing background (to main dc only) and all 60 seconds and ring off
// total = 196000 (-113k)
// execution = 106000 (-70k)
// graphics = 39000 (-44k)
// display = 49920
//
// drawing background (to main dc and one buffer) and all 60 seconds and ring off
// total = 201000 (+5k)
// execution = 111000 (+5k)
// graphics = 39000 (+0k)
// display = 49920
//
// drawing background (to main dc and one buffer) and all 60 seconds and ring on again
// total = 325000 (+124k)
// execution = 189000 (+78k)
// graphics = 85000 (+46k)
// display = 49920

    // Handle the partial update event - not called during high power mode (glance active)
    (:m2face)
    function onPartialUpdate(dc)
    {
    	var clockTime = System.getClockTime();
    	updateTimeNowValue = Time.now().value();
    	var minute = clockTime.min;
    	var second = clockTime.sec;

    	sampleHeartRate(second, second!=lastPartialUpdateSec);
    
    	// check for some status icons changing dynamically
    	{
 			var deviceSettings = System.getDeviceSettings();	// 960 bytes, but uses less code memory
	
	    	if ((fieldActivePhoneStatus!=null && (fieldActivePhoneStatus != deviceSettings.phoneConnected)) ||
	    		(fieldActiveNotificationsStatus!=null && (fieldActiveNotificationsStatus != (deviceSettings.notificationCount > 0))) ||
	    		(fieldActiveNotificationsCount!=null && (fieldActiveNotificationsCount != deviceSettings.notificationCount)) ||
	    		(fieldActiveLTEStatus!=null && (fieldActiveLTEStatus != lteConnected())) )
	    	{
	        	WatchUi.requestUpdate();
	    	}
	    }
    
		if (propSecondIndicatorOn)
		{ 
	 		// it seems as though occasionally onPartialUpdate can skip a second
	 		// so check whether that has happened, and within the same minute since last full update
	 		// - but only for certain refresh styles
	 		//
	 		// But there is also a strange case when exiting high power mode where lastPartialUpdateSec may already be set to the current second 
    		if ((propSecondRefreshStyle==1/*REFRESH_EVERY_MINUTE*/) || (propSecondRefreshStyle==2/*REFRESH_ALTERNATE_MINUTES*/))
    		{
		 		var prevSec = ((second+59)%60);
		 		if (prevSec<second && second!=lastPartialUpdateSec)		// check earlier second in same minute
		 		{
		 			doPartialUpdateSec(dc, prevSec, minute);
		 		}
			}

	 		// do the partial update for this current second
	 		doPartialUpdateSec(dc, second, minute);
	 		lastPartialUpdateSec = second;	// set after calling doPartialUpdateSec
        }
    }

    (:m2face)
    function doPartialUpdateSec(dc, secondsIndex, minuteIndex)
    {
    	if (secondsIndex!=lastPartialUpdateSec)		// check whether everything is up to date already (from doUpdate)
    	{		
 			var clearIndex;
	    	if (propSecondRefreshStyle==0/*REFRESH_EVERY_SECOND*/)
	    	{
	        	// Clear the previous second indicator we drew and restore the background
	    		clearIndex = lastPartialUpdateSec;
	    	}
	    	else if (propSecondRefreshStyle==2/*REFRESH_ALTERNATE_MINUTES*/ && (minuteIndex%2)==1)
	    	{
	        	clearIndex = secondsIndex;
			}
			else
			{
				clearIndex = -1;
			}

	        if (clearIndex>=0)
	        {
				drawBuffer(clearIndex, dc);

				// copy from the offscreen buffer over the second indicator
    			setSecondClip(dc, clearIndex);
	    		
	    		//dc.setColor(-1/*COLOR_TRANSPARENT*/, Graphics.COLOR_GREEN);	// check the buffer is clearing the whole of clip region
        		//dc.clear();
				
				//if (bufferBitmap==null)
				//{
	    		//	dc.setColor(-1/*COLOR_TRANSPARENT*/, propBackgroundColor);
	        	//	dc.clear();
				//}
				//else
				//{
					dc.drawBitmap(bufferX, bufferY, bufferBitmap);
				//}
	       	}

			if (propSecondRefreshStyle==2/*REFRESH_ALTERNATE_MINUTES*/ && (minuteIndex%2)==1)
			{
				// redraw the indicator following the one we just cleared
				// as some of it might have been erased
				// - but need to keep using the clip region we used for the erase above
				var nextIndex = (clearIndex+1)%60; 
				drawSecond(dc, nextIndex, nextIndex);
	
				// in this mode we also always draw the indicator at 0
				// - so check if that needs redrawing too after erasing the indicator at 1
				if (clearIndex==1)
				{
					drawSecond(dc, 0, 0);
				}
			}
			else
			{
    			setSecondClip(dc, secondsIndex);
				drawSecond(dc, secondsIndex, secondsIndex);
			}
		}
    }

    (:m2face)
    function setSecondClip(dc, index)
    {
    	index += (propSecondMoveInABit ? 60 : 0);
   		dc.setClip(-8/*SECONDS_SIZE_HALF*/ + secondsX[index], -8/*SECONDS_SIZE_HALF*/ + secondsY[index], 8/*SECONDS_SIZE_HALF*/*2, 8/*SECONDS_SIZE_HALF*/*2);
    }

    function drawSecond(dc, startIndex, endIndex)
    {
		if (propSecondResourceIndex<dynResNum)		// sometimes onPartialUpdate is called between onSettingsChanged and onUpdate - so this resource could be null
		{
			var dynamicResource = getDynamicResource(propSecondResourceIndex);
			if (dynamicResource!=null)
			{
		    	var curCol = COLOR_NOTSET;
		   		var xyIndex = startIndex + (propSecondMoveInABit ? 60 : 0);
		    	for (var index=startIndex; index<=endIndex; index++, xyIndex++)
		    	{
					var col = getColor64(secondsColorIndexArray[index]);
			
			        if (curCol != col)
			        {
			        	curCol = col;
			       		dc.setColor(curCol, -1/*COLOR_TRANSPARENT*/);	// seconds color
			       	}
			       	//dc.setColor(col, graphics.COLOR_GREEN);
			       	//dc.setColor(getColor64(4+42+(index*4)%12), -1/*COLOR_TRANSPARENT*/);
			       	
			       	//var s = characterString.substring(index+9, index+10);
					//var s = StringUtil.charArrayToString([(index + SECONDS_FIRST_CHAR_ID).toChar()]);
					//var s = (index + 21/*SECONDS_FIRST_CHAR_ID*/).toChar().toString();
		        	dc.drawText(-8/*SECONDS_SIZE_HALF*/ + secondsX[xyIndex], -8/*SECONDS_SIZE_HALF*/ + secondsY[xyIndex], dynamicResource, (index + 21/*SECONDS_FIRST_CHAR_ID*/).toChar().toString(), 2/*TEXT_JUSTIFY_LEFT*/);
				}
			}
		}
    }

	function getProfileSunTime(time, t1, startEndShift)
	{
		t1 >>= startEndShift;
		
		if ((t1&(0x01/*PROFILE_START_SUNRISE*/|0x02/*PROFILE_START_SUNSET*/))!=0)
		{
			// remove the 12 hour offset used when it is saved to storage
			// note we add this on rather than subtracting since we are doing modulo 24*60 later (and want the value to be positive)
			time += 12*60;
		
			// riseSetIndex==0 is sunrise
			// riseSetIndex==1 is sunset
			var t = sunTimes[(t1&0x02/*PROFILE_START_SUNSET*/)/0x02/*PROFILE_START_SUNSET*/];
			//var t = sunTimes[((t1&PROFILE_START_SUNRISE)!=0) ? 0 : 1];

			if (t!=null)
			{
				time += t;		// add to the sunrise or sunset time
			}
	
			// since we are doing modulo 24*60 below, doing the following would make no difference so don't need it ...
			//else
			//{			
			//	//if ((riseSetIndex==0 && !sunTimes[2]) ||	// looking for sunrise but sun doesn't rise (so permanent night)
			//	//	(riseSetIndex==1 && sunTimes[2]))		// looking for sunset but sun rises (so permanent day)
			//	if ((riseSetIndex==0) != sunTimes[2])
			//	{
			//		time += 24*60;		// set time offset from end of day
			//	}
			//	//else
			//	//{
			//	//	time += 0;			// set time offset from start of day
			//	//}
			//}
			
			// return time modulo 24 hours
			time = time%(24*60);
		}

		return time;
	}

	(:m2face)	
	function checkProfileToActivate(timeNow)
	{
		var doActivate = profileActive;		// stick with current profile until told otherwise
		
		if (glanceActive)		// during glance
		{
			if (profileGlance<0)
			{
				if (profileData[profileActive*6 + 5]>=0 && profileData[profileActive*6 + 5]<(PROFILE_NUM_USER+PROFILE_NUM_PRESET))
				{
					doActivate = profileData[profileActive*6 + 5];
					profileGlanceReturn = profileActive;	// return to this profile after glance 
				}
			}
			else
			{
				doActivate = profileGlance;		// keep glance profile active until glance ends
			}
		}
		else
		{
			if (profileGlance>=0)
			{
				doActivate = profileGlanceReturn;
				profileGlance = -1; 
			}
		}
		
		var timeNowValue = timeNow.value();
		
		if (!(glanceActive && profileGlance>=0) && timeNowValue>=profileDelayEnd)
		{
			doActivate = 0;		// assume want to be in normal watch settings

			var dateInfoShort = Time.Gregorian.info(timeNow, Time.FORMAT_SHORT);
			var nowDayNumber = (dateInfoShort.day_of_week+5)%7;		// 1=Sun, 2=Mon 3=Tue, etc so convert to 0=Mon, 1=Tue ... 6=Sun
			var prevDayNumber = (nowDayNumber+6)%7;
	        var timeNowInMinutesToday = dateInfoShort.hour*60 + dateInfoShort.min;
	        var timeNowValueWholeMinute = timeNowValue + ((60-dateInfoShort.sec)%60);
			var randomNum = 0;
			var randomProfiles = new[PROFILE_NUM_USER];
			var randomEvents = new[PROFILE_NUM_USER];
			var randomEventsTotal = 0;
			
			for (var i=0; i<PROFILE_NUM_USER; i++)
			{
				if (doActivate==0)	// not found a profile to activate yet
				{
					var startTime = profileData[i*6 + 0];
					var endTime = profileData[i*6 + 1];

					// see if the start or end time uses sunrise/sunset					
					if ((profileData[i*6 + 3]&(0x01/*PROFILE_START_SUNRISE*/|0x02/*PROFILE_START_SUNSET*/|0x04/*PROFILE_END_SUNRISE*/|0x08/*PROFILE_END_SUNSET*/))!=0)
					{
						calculateSun(dateInfoShort);
						
						startTime = getProfileSunTime(startTime, profileData[i*6 + 3], 0);
						endTime = getProfileSunTime(endTime, profileData[i*6 + 3], 2);
					}
					
					var dayFlags = profileData[i*6 + 2];
					if (startTime<endTime)		// Note: if 2 times are equal then go for 24 hours (e.g. by default both times are 0)
					{
						if (timeNowInMinutesToday>=startTime && timeNowInMinutesToday<endTime && (dayFlags&(0x01<<nowDayNumber))!=0)	// current day set?
						{
							doActivate = i;
						}
					}
					else
					{
						// goes over midnight
						if ((timeNowInMinutesToday>=startTime && (dayFlags&(0x01<<nowDayNumber))!=0) ||			// current day 
							(timeNowInMinutesToday<endTime && (dayFlags&(0x01<<prevDayNumber))!=0))				// previous day
						{
							doActivate = i;
						}
					}
				}

				var numEvents = profileData[i*6 + 4];
				if (numEvents>0)
				{
					randomProfiles[randomNum] = i;
					randomEvents[randomNum] = numEvents;
					randomEventsTotal += numEvents;
					randomNum++;
				}
			}
			
			// doActivate must be in range (0 to PROFILE_NUM_USER-1) when we get here
			if ((profileData[doActivate*6 + 3]&0x10/*PROFILE_BLOCK_MASK*/)==0)
			{
				if (profileRandom>=0)					// random already active
				{
					if (timeNowValue<profileRandomEnd)
					{
						doActivate = profileRandom;		// stick with same random
					}
					else
					{
						profileRandom = -1;				// end current random
					}
				}
				
				if (profileRandom<0 && randomNum>0 && profileRandomLastMin!=dateInfoShort.min)
				{
					profileRandomLastMin = dateInfoShort.min;
				
					var r = Math.rand()%(24*60);		// number of minutes in a day
					if (r < randomEventsTotal)
					{
						r = Math.rand()%randomEventsTotal;
						for (var i=0; i<randomNum; i++)
						{
							var numEvents = randomEvents[i];
							
							r -= numEvents;
							
							if (r < 0)
							{
								var lenMinutes = 3 + Math.rand()%12;		// 3 to 14 minutes
								// scale length depending on how many events per day for this particular random profile
								// minimum of 1 minute long
								// if 9 events a day then roughly 2/3 as long
								// if 18 events a day then roughly 1/2 as long
								// if 36 events a day then roughly 1/3 as long
								// if 72 events a day then roughly 1/5 as long
								// if 144 events a day then roughly 1/9 as long
								// if 216 events a day then roughly 1/13 as long
								lenMinutes = 1 + ((lenMinutes*18 + numEvents/2) / (17 + numEvents));
								
								profileRandom = randomProfiles[i];
								profileRandomEnd = timeNowValueWholeMinute + lenMinutes*60;
								doActivate = profileRandom;
								
								break;
							}
						}
					}
				}
			}
			else
			{
				profileRandom = -1;
			}

			if (demoProfilesOn /*|| forceDemoProfiles*/)
			{
				if (doActivate!=0)
				{
					// end current demo profile
					demoProfilesCurrentEnd = 0;
				}
				else
				{
					if (demoProfilesLast >= demoProfilesFirst)
					{
						if (timeNowValue >= demoProfilesCurrentEnd)
						{
							var nextProfile = demoProfilesCurrentProfile + 1;
							if (nextProfile < demoProfilesFirst || nextProfile > demoProfilesLast)
							{
								nextProfile = demoProfilesFirst;
							}

							demoProfilesCurrentProfile = nextProfile;
							// if within 1 minute of end time of previous demo profile - then just add 5 minutes to end of previous
							demoProfilesCurrentEnd = ((timeNowValue-demoProfilesCurrentEnd < 60) ? demoProfilesCurrentEnd : timeNowValueWholeMinute) + 5*60;	// 5 minutes
						}
					
						if (demoProfilesCurrentProfile >= 0)
						{
							doActivate = demoProfilesCurrentProfile; 
						}
					}
				}
			}
		}

		return doActivate;
	}
	
	(:m2app)
	function checkProfileToActivate(timeNow)
	{
		return profileActive;
	}
	
	function checkReloadDynamicResources()
	{
		return false;
	}
	
	var dayWeekYearCalculatedDay = [-1, -1, -1];	// dayOfYear, ISO, Calendar
	var dayOfYear;		// the day number of the year (0-364)
	var ISOWeek;		// in ISO format the first week of the year always includes the first Thursday
	var ISOYear;
	var CalendarWeek;	// in Calendar format the first week of the year always includes 1st Jan
	var CalendarYear;

	// 500 code bytes + 100 data
//	function printMoment(m, s)
//	{
//		var i = Time.Gregorian.info(m, Time.FORMAT_SHORT);
//		System.println(Lang.format(s + " Local $1$-$2$-$3$ $4$:$5$:$6$", [ i.year.format("%4d"), i.month.format("%02d"), i.day.format("%02d"), i.hour.format("%02d"), i.min.format("%02d"), i.sec.format("%02d") ]));
//		i = Time.Gregorian.utcInfo(m, Time.FORMAT_SHORT);
//		System.println(Lang.format(s + " UTC $1$-$2$-$3$ $4$:$5$:$6$", [ i.year.format("%4d"), i.month.format("%02d"), i.day.format("%02d"), i.hour.format("%02d"), i.min.format("%02d"), i.sec.format("%02d") ]));
//	}
	
	function calculateDayWeekYearData(index, firstDayOfWeek, dateInfoMedium)
	{
		// use noon for all these times to be safe when getting dateInfo
	
		var todayNoon = new Time.Moment(updateTimeTodayValue + 12*60*60);		// local time for local noon today
		var todayNoonValue = todayNoon.value();
		if (todayNoonValue == dayWeekYearCalculatedDay[index])
		{
			return;
		}

		var gregorian = Time.Gregorian;
		var timeZoneOffsetDuration = gregorian.duration({:seconds => updateTimeZoneOffset});

		var tempYear = {:year => dateInfoMedium.year, :month => 1, :day => 1, :hour => 12, :minute => 0, :second => 0};
		var startOfYearNoon = gregorian.moment(tempYear).subtract(timeZoneOffsetDuration);
		//printMoment(startOfYearNoon, "startOfYearNoon");
		var durationToStartOfYear = todayNoon.subtract(startOfYearNoon);
		//var secs = duration.value();
		//var mins = secs / 60.0;
		//var hours = mins / 60.0;
		//var days = Math.round(hours / 24.0) + 1;
		//System.println("days=" + durationToStartOfYear.value() / 86400.0);
		var days = Math.round(durationToStartOfYear.value() / 86400.0).toNumber();

		dayWeekYearCalculatedDay[0] = todayNoonValue;
		dayOfYear = days + 1;
		if (index==0)
		{
			return;
		}
		
		// Garmin numbers days of the week as 1=sun, 2=mon, 3=tue, 4=wed, 5=thu, 6=fri, 7=sat
		//
		// 1st ISO week has the first Thu of the gregorian year in it
		// If first day of week is set to Mon then Jan 1 is in week 1 if Jan 1 is Mon, Tue, Wed, Thu
		// If first day of week is set to Sun then Jan 1 is in week 1 if Jan 1 is Sun, Mon, Tue, Wed, Thu
		// If first day of week is set to Sat then Jan 1 is in week 1 if Jan 1 is Sat, Sun, Mon, Tue, Wed, Thu
	       					
		var dateInfoStartOfYear = gregorian.info(startOfYearNoon, Time.FORMAT_SHORT);	// get date info for noon to be safe
 		var numberInWeekOfJan1 = ((dateInfoStartOfYear.day_of_week - firstDayOfWeek + 7) % 7);	// 0-6
		var weeks = (days + numberInWeekOfJan1) / 7;
		var year = dateInfoMedium.year;

		var numberInWeekOfThu = ((gregorian.DAY_THURSDAY - firstDayOfWeek + 7) % 7);	// 0-6
		
		if (index==1)
		{
			if (numberInWeekOfJan1>=0 && numberInWeekOfJan1<=numberInWeekOfThu)
			{
				// jan1 is in week 1 of the year
				weeks += 1;
			}
			//else
			//{
			//	// jan1 is in last week of previous year
			//}
		}
		else
		{
			weeks += 1;
		}

		var checkWeeksLessThan1 = (index==1 && weeks<1);		// only for ISO
		var checkWeeksGreaterThan52 = (weeks>52);

		if (checkWeeksLessThan1)		// check to find last week of previous year
		{
			var prevYear = dateInfoMedium.year-1;
			tempYear.remove(:year);
			tempYear.put(:year, prevYear);
			var startOfPrevYearNoon = gregorian.moment(tempYear).subtract(timeZoneOffsetDuration);
			//var startOfPrevYearNoon = gregorian.moment({:year => prevYear, :month => 1, :day => 1, :hour => 12, :minute => 0, :second => 0}).subtract(timeZoneOffsetDuration);
			var dateInfoStartOfPrevYear = gregorian.info(startOfPrevYearNoon, Time.FORMAT_SHORT);	// get date info for noon to be safe
			var numberInWeekOfJan1PrevYear = ((dateInfoStartOfPrevYear.day_of_week - firstDayOfWeek + 7) % 7);	// 0-6
			
			var durationToJan1PrevYear = todayNoon.subtract(startOfPrevYearNoon);
			var daysToJan1PrevYear = Math.round(durationToJan1PrevYear.value() / 86400.0).toNumber();
			var daysToStartOfWeekYear = daysToJan1PrevYear + numberInWeekOfJan1PrevYear;
			weeks = daysToStartOfWeekYear / 7;
			year = prevYear;

			if (numberInWeekOfJan1PrevYear<=numberInWeekOfThu)
			{
				// jan1 prev year is in week 1 of the year
				weeks += 1;
			}
			//else
			//{
			//	// jan1 prev year is not in week 1 of the year - so our calculated week number is fine
			//}
		}
		else if (checkWeeksGreaterThan52)	// check to see if in first week of next year
		{
			var nextYear = dateInfoMedium.year+1;
			tempYear.remove(:year);
			tempYear.put(:year, nextYear);
			var startOfNextYearNoon = gregorian.moment(tempYear).subtract(timeZoneOffsetDuration);
			//var startOfNextYearNoon = gregorian.moment({:year => nextYear, :month => 1, :day => 1, :hour => 12, :minute => 0, :second => 0}).subtract(timeZoneOffsetDuration);
			var dateInfoStartOfNextYear = gregorian.info(startOfNextYearNoon, Time.FORMAT_SHORT);	// get date info for noon to be safe
			var numberInWeekOfJan1NextYear = ((dateInfoStartOfNextYear.day_of_week - firstDayOfWeek + 7) % 7);	// 0-6
			
			var checkInFirstWeek;
			
			if (index==1)
			{
				checkInFirstWeek = (numberInWeekOfJan1NextYear<=numberInWeekOfThu);

				//if (numberInWeekOfJan1NextYear<=numberInWeekOfThu)
				//{
				//	// jan1 next year is in week 1 of the year
				//	checkInFirstWeek = true;
				//}
				//else
				//{
				//	// jan1 next year is in last week of previous year - so our calculated week number is fine
				//	checkInFirstWeek = false;
				//}
			}
			else
			{
				checkInFirstWeek = true;
			}

			if (checkInFirstWeek)
			{
				// so see if we are in the same week as jan1 next year
				var durationToJan1NextYear = startOfNextYearNoon.subtract(todayNoon);
				var daysToJan1NextYear = Math.round(durationToJan1NextYear.value() / 86400.0).toNumber();
				if (daysToJan1NextYear <= numberInWeekOfJan1NextYear)
				{
					 weeks = 1;		// in first week of next year
					 year = nextYear;
				}
			}
		}

		dayWeekYearCalculatedDay[index] = todayNoonValue;
		if (index==1)
		{
			ISOWeek = weeks;
			ISOYear = year;
		}
		else
		{
			CalendarWeek = weeks;
			CalendarYear = year;
		}
	}

	//const heartBinSize = 5;
	//const heartNumBins = 12;
	var heartStarting;
	var heartChartVisible = false;
	var heartCalculatedTime = -1;
	var heartDisplayMin;
	var heartDisplayMax;
	var heartDisplayAverage;
	var heartDisplayLatest;
	var heartDisplayBins = new[12/*heartNumBins*/]b;
	
	var heartSampledSecond = 0;
	var heartSamples = new[60]b;

	var heartMaxZone5 = 200;

	function initHeartSamples(timeNowValue)
	{
		heartStarting = timeNowValue;	// set start time for initial frequent heart updates

		for (var i=0; i<60; i++)
		{
			heartSamples[i] = 255;	// means not set
			heartDisplayBins[i/5/*heartBinSize*/] = 0;
		}
		
		var heartRateZones = UserProfile.getHeartRateZones(0/*UserProfile.HR_ZONE_SPORT_GENERIC*/);
		if (heartRateZones!=null && (heartRateZones instanceof Array) && heartRateZones.size()>5)
		{
			heartMaxZone5 = heartRateZones[5];
			if (heartMaxZone5==null || heartMaxZone5<=0)	// max must be at least 1 to avoid potential zero divide
			{
				heartMaxZone5 = 200;
			}
		}
	}

	function sampleHeartRate(second, checkRequestUpdate)
	{
		//System.println("sampleHeartRate=" + second);
		if (heartSampledSecond!=second)
		{
			// clear samples between last one and now
			for (var i=(heartSampledSecond+1)%60; i!=second; i=(i+1)%60)
			{
				heartSamples[i] = 255;	// means not set
			}

			var info = Activity.getActivityInfo();
			heartSamples[second] = ((info!=null && info.currentHeartRate!=null) ? getMinMax(info.currentHeartRate, 0, 254) : 255);

			heartSampledSecond = second;
			
			if (heartChartVisible && checkRequestUpdate && (updateTimeNowValue<heartStarting+60) && ((second%5/*heartBinSize*/)==0))
			{
        		WatchUi.requestUpdate();
			}
		}			
	}
	
	function calculateHeartRate(minute, second)
	{
		//System.println("calculateHeartRate=" + second);
		var t = minute*60 + second;
		if (heartCalculatedTime!=t)
		{
			heartCalculatedTime = t;

			heartDisplayMin = null;
			heartDisplayMax = null;
			heartDisplayAverage = null;
			heartDisplayLatest = null;

			var allSum = 0;
			var allCount = 0;
			var bin = 0;
			var binSum = 0;
			var binCount = 0;
			var isLastI = false;
			// start from bin following this second's bin (keeps the display bars moving nicely without gaps appearing)
			for (var i=((second/5/*heartBinSize*/ + 1)*5/*heartBinSize*/)%60; !isLastI; i=(i+1)%60)
			{		
				var r = heartSamples[i];
				if (r != 255)	// value has been set
				{
					heartDisplayLatest = r;
				
					if (heartDisplayMin==null || r<heartDisplayMin)
					{
						heartDisplayMin = r;
					}
						
					if (heartDisplayMax==null || r>heartDisplayMax)
					{
						heartDisplayMax = r;
					}

					allSum += r;
					allCount++;
					
					binSum += r;
					binCount++;					
				}
				
				isLastI = (i==second);
				if ((bin%5/*heartBinSize*/)==(5/*heartBinSize*/-1) || isLastI)
				{
					heartDisplayBins[bin/5/*heartBinSize*/] = ((binCount>0) ? (binSum/binCount) : 0);
					
					binSum = 0;
					binCount = 0;
				}
				bin++;
			}

			if (allCount>0)
			{
				heartDisplayAverage = (allSum + allCount/2)/allCount;
			}

			// resort to sensor history if no heart rate measured in last minute
			if (heartDisplayLatest==null && hasHeartRateHistory)
			{
				var heartSample = SensorHistory.getHeartRateHistory({:period => 1}).next();
				if (heartSample!=null && heartSample.data!=null)
				{
					heartDisplayLatest = heartSample.data.toNumber();
				}
			}
		}
	}

// execution time approx 12000ms for 60x(setColor+drawRectangle) (outer ring is approx 7000ms)
// only 6000ms for 1xsetColor + 60xdrawRectangle
// 6000ms for drawLine
// 6000ms for drawPoint

	//const heartChartHeight = 20;
	//const heartOneBarWidth = 4;
	//const heartChartXOffset = 2;
	//const heartBarsWidth = 51;	(12/*heartNumBins*/*4/*heartOneBarWidth*/ - 1 + 2*2/*heartChartXOffset*/)
	//const heartAxesWidth = 55;	(12/*heartNumBins*/*4/*heartOneBarWidth*/ + 3 + 2*2/*heartChartXOffset*/)
	//const heartChartWidth = 52;	(12/*heartNumBins*/*4/*heartOneBarWidth*/ + 2*2/*heartChartXOffset*/)

	function drawHeartChart(useDc, x, y, colorChart, colorAxes, axesSide, axesBottom)
	{
		x += (axesSide ? (2 + 2/*heartChartXOffset*/) : 2/*heartChartXOffset*/);

		useDc.setColor(colorChart, -1/*COLOR_TRANSPARENT*/);

		// draw the bars
		for (var i=0; i<12/*heartNumBins*/; i++)
		{
			var h = getMinMax((heartDisplayBins[i]*(20/*heartChartHeight*/+1))/heartMaxZone5, 0, 20/*heartChartHeight*/);

			useDc.fillRectangle(x + 4/*heartOneBarWidth*/*i, y - h, 4/*heartOneBarWidth*/-1, h+1);	// h+1 so it goes to same position as axes (for alignment with text when no axes drawn)
			//useDc.drawPoint(100+x - dcX, 220-h - dcY);
			//useDc.drawLine(i, 0, i, 30);
		}

		if (axesSide)
		{
			useDc.setColor(colorAxes, -1/*COLOR_TRANSPARENT*/);
			
			// draw the axes
			useDc.fillRectangle(x-2, y - 20/*heartChartHeight*/, 1, 20/*heartChartHeight*/+1);				// left
			useDc.fillRectangle(x+(4/*heartOneBarWidth*/*12/*heartNumBins*/), y-20/*heartChartHeight*/, 1, 20/*heartChartHeight*/+1);		// right
			
			if (axesBottom)
			{
				useDc.fillRectangle(x-1, y, (4/*heartOneBarWidth*/*12/*heartNumBins*/)+1, 1);				// bottom
			}
		}
	}

	var positionGot = false;
	var positionLatitude = 0.0;
	var positionLongitude = 0.0;
	var positionAltitude = 0.0;

	// 350 code bytes
	function calculatePosition()
	{
		// ideas on when to call:
		// if not got a position yet - keep checking every onUpdate
		// if have a position and not using position - check every so often for new position
		// if using position - check every update for latest value 
		//
		// get altitude either from Activity.getActivityInfo() at same time as location
		// or from SensorHistory on demand

		var info = Activity.getActivityInfo();
		if (info!=null)
		{
			if (info.currentLocation!=null && info.currentLocationAccuracy>0)		// 0 accuracy means GPS not available
			{
				//System.println("currentLocationAccuracy=" + info.currentLocationAccuracy);
				var l = info.currentLocation.toDegrees();
				positionGot = true;
				positionLatitude = l[0].toFloat();
				positionLongitude = l[1].toFloat();
			}
		}

		if (info!=null && info.altitude!=null)
		{
			positionAltitude = info.altitude; 
			//System.println("alt activity=" + info.altitude);
		}
		else if (hasElevationHistory)
		{
			var elevationSample = SensorHistory.getElevationHistory({:period => 1}).next();
			if (elevationSample!=null && elevationSample.data!=null)
			{ 
				positionAltitude = elevationSample.data.toFloat();
				//System.println("alt history=" + altitude);
			}
		}

//		if (forceTestLocation)
//		{
//			positionGot = true;
//
//			// Windermere lat=54.380810, long=-2.907530
//			//positionLatitude = 54.380810;
//			//positionLongitude = -2.907530;
//			
//			// Windermere
//			positionLatitude = 54.3787142d;	// 54 22 43
//			positionLongitude = -2.9044238d;	// -2 54 16
//			//positionAltitude = 140.0;	// m
//			positionAltitude = 0.0;	// m
//			
//			//positionLongitude += 0.01;				// 3 secs change
//			//positionLongitude += 0.1;				// 30 secs change in sunrise
//			//useAltitude = 1.0;	// m		// 15 seconds change
//			//useAltitude = 100.0;	// m		// 3 minutes change
//			//useAltitude = 1000.0;	// m	// 10 minutes change
//			
//			// Trondheim, Trøndelag, 7011, Norway
//			//positionLatitude = 63.4305658d;
//			//positionLongitude = 10.3951929d;
//			
//			//positionLatitude = 68.0;
//			//positionLongitude = 0.0;
//	
//			//positionLatitude = -70.5;
//			//positionLongitude = 0.0;
//			
//			// Longyearbyen, Svalbard, 9170, Norway
//			//positionLatitude = 78.2231558d;
//			//positionLongitude = 15.6463656d;
//		}
	}

	// day, latitude, longitude, altitude
	var sunCalculatedDay = -1;
	var sunCalculatedLatitude;
	var sunCalculatedLongitude;
	var sunCalculatedAltitude;

	// 0==sunrise today, 1==sunset today, 2==sun rises at all today?
	// 3==sunrise tomorrow, 4==sunset tomorrow, 5==sun rises at all tomorrow?
	// 6==next sunevent, 7==next sunevent is rise?
	var sunTimes = new[8];		// hour*60 + minute

	// 1600 code bytes
	function calculateSun(dateInfoShort)
	{
		if (!positionGot)
		{
			return;
		}

		var useAltitude = (propSunAltitudeAdjust ? positionAltitude : 0.0);

		var todayValue = updateTimeTodayValue;
		if (sunCalculatedDay!=todayValue ||
			sunCalculatedLatitude!=positionLatitude ||
			sunCalculatedLongitude!=positionLongitude ||
			sunCalculatedAltitude!=useAltitude)
		{
			// remember when & where we did this calculation
			sunCalculatedDay = todayValue;		
			sunCalculatedLatitude = positionLatitude;
			sunCalculatedLongitude = positionLongitude;
			sunCalculatedAltitude = useAltitude;
	
			// this is in local time at that date
			// gregorian.info displays this time as 13:00
			// gregorian.utcInfo displays this time as 12:00
	
			// whereas this time in March before summer time
			// gregorian.info displays this time as 12:00
			// gregorian.utcInfo displays this time as 12:00
	
			// Running this in May (summer time) then timeZoneOffset is 3600 (UTC + 1)
	
			// Running this in May (summer time) at 20:48
			// gregorian.info displays this time as 20:48
			// gregorian.utcInfo displays this time as 19:48
			
			// Running this in May (summer time)
			// gregorian.info displays this time as 00:00
			// gregorian.utcInfo displays this time as 23:00 on previous date
	
			calculateSunDay(0, dateInfoShort.day_of_week);		// today
			calculateSunDay(1, dateInfoShort.day_of_week);		// tomorrow
		}
			
		// calculate next sun event (on every call)
		sunTimes[6] = null;				// assume don't know time of next sun event
		sunTimes[7] = !sunTimes[2];		// and if the sun rises today then next event is sunset (or if it doesn't rise then sunset)
		
		var timeNowInMinutesToday = dateInfoShort.hour*60 + dateInfoShort.min;
		if (sunTimes[0]!=null && timeNowInMinutesToday<sunTimes[0])	// before sunrise?
		{
			sunTimes[6] = sunTimes[0];
			sunTimes[7] = true;			// sunrise
		}
		else if (sunTimes[1]!=null)		// sunset occurs today
		{
			if (timeNowInMinutesToday<sunTimes[1])		// before sunset?
			{
				sunTimes[6] = sunTimes[1];
				sunTimes[7] = false;	// sunset
			}
			else if (sunTimes[3]!=null && timeNowInMinutesToday<sunTimes[3])		// before sunrise tomorrow?
			{
				sunTimes[6] = sunTimes[3];
				sunTimes[7] = true;		// sunrise
			}
		}

		//System.println("sunTimes=" + sunTimes.toString());
	}
	
	function calculateSunDay(dayOffset, nowDayOfWeek)
	{
		var gregorian = Time.Gregorian;
		var toRadians = (Math.PI/180.0d);

		// start of today + 12 hours + time zone
		var todayNoonUTC = new Time.Moment(updateTimeTodayValue + 12*60*60 + updateTimeZoneOffset + dayOffset*86400);	// UTC time for local noon today (or tomorrow)
		var todayNoonValue = todayNoonUTC.value();

		//var jan1st2000NoonUTC = gregorian.moment({:year => 2000, :month => 1, :day => 1, :hour => 12, :minute => 0, :second => 0 });		// value prints out as 946728000
		var jan1st2000NoonUTC = new Time.Moment(946728000);		// from http://www.onlineconversion.com/unix_time.htm - this one seems correct
		//var jan1st2000NoonUTC = new Time.Moment(946731600);	from https://www.omnicalculator.com/conversion/unix-time - seems out by 1 hour?!
		
		var durationSinceJan1st2000 = todayNoonUTC.subtract(jan1st2000NoonUTC);
		var daysSinceJan1st2000 = Math.round(durationSinceJan1st2000.value() / 86400.0);
		
		// Terrestrial Time is 32 seconds ahead of TAI (International Atomic Time)
		// And TAI is 37 seconds ahead of UTC
		var UTC2TT = (37+32)/86400.0;		// 0.0008

		var n = daysSinceJan1st2000 + UTC2TT;
		
		var jStar = n - positionLongitude/360.0d;			// correct by up to + or - half a day depending on longitude
		var m = 357.5291 + 0.98560028d * jStar;
		m -= Math.floor(m/360)*360;			// modulo 360
		
		var mRadians = m*toRadians; 
		var c = 1.9148*Math.sin(mRadians) + 0.0200*Math.sin(mRadians*2) + 0.0003*Math.sin(mRadians*3);
		
		//var lambda = m + c + 180 + 102.9372;
		var lambda = m + c + 180 + 102.984378;
		lambda -= Math.floor(lambda/360)*360;		// modulo 360
		
		var sinDeclination = Math.sin(lambda*toRadians) * Math.sin(23.44*toRadians);	// this varies between +-23.44 degrees
		var cosDeclination = Math.sqrt(1 - sinDeclination*sinDeclination);				// so cos of declination will be positive
		
		var latRadians = positionLatitude*toRadians;
		//var w1 = Math.sin(-0.83*toRadians) - Math.sin(latRadians)*sinDeclination;
		var altAdjust = ((sunCalculatedAltitude>0.0) ? ((2.076/60.0)*Math.sqrt(sunCalculatedAltitude)) : 0.0);
		var w1 = Math.sin((-0.83 - altAdjust)*toRadians) - Math.sin(latRadians)*sinDeclination;		// with height adjust
		var w2 = Math.cos(latRadians)*cosDeclination;

		var cosW;
		// w2 will always be tending to positive - since lat is either 90-delta or -90+delta
		if (w2>0.0)
		{
			cosW = w1/w2;
		}
		else
		{
			// either permanent day or permanent night
			// sign of w1 determines sign of cosW
			cosW = ((w1<0.0) ? -2.0 : 2.0);
		}
		
		var dayOffset3 = dayOffset*3;
		if (cosW < -1.0 /*permanent day*/ || cosW > 1.0 /*permanent night*/)
		{
			sunTimes[dayOffset3] = null;
			sunTimes[dayOffset3 + 1] = null;
			sunTimes[dayOffset3 + 2] = (cosW < -1.0);
		}
		else
		{		
			// days since jan1st2000NoonUTC
			var jTransit = jStar + 0.0053*Math.sin(mRadians) - 0.0069*Math.sin(lambda*toRadians*2);
			jTransit -= UTC2TT;		// convert back to UTC time
				
			//var durationTransit = gregorian.duration({:seconds => jTransit*24*60*60});
			//var momentTransit = jan1st2000NoonUTC.add(durationTransit);
			//printMoment(momentTransit, "momentTransit");
	
			//var w = Math.acos(cosW);
			//System.println("w=" + w + " cosW=" + cosW + " w1=" + w1 + " w2=" + w2);
			var offsetFromTransit = Math.acos(cosW) / (toRadians*360);	// convert to degrees, then divide by 360 to get in range +-1

			//printMoment(jan1st2000NoonUTC.add(gregorian.duration({:seconds => (jTransit - offsetFromTransit)*24*60*60})), "momentRise");
			//printMoment(jan1st2000NoonUTC.add(gregorian.duration({:seconds => (jTransit + offsetFromTransit)*24*60*60})), "momentSet");

			sunTimes[dayOffset3] = jTimeToHourMinute(jan1st2000NoonUTC, jTransit - offsetFromTransit, nowDayOfWeek);		// up to -0.5 day
			sunTimes[dayOffset3 + 1] = jTimeToHourMinute(jan1st2000NoonUTC, jTransit + offsetFromTransit, nowDayOfWeek);		// up to +0.5 day
			sunTimes[dayOffset3 + 2] = true;
		}
	}

	function jTimeToHourMinute(jan1st2000NoonUTC, jTime, nowDayOfWeek)
	{
		// round to nearest minute
		var sunInfo = Time.Gregorian.info(jan1st2000NoonUTC.add(Time.Gregorian.duration({:minutes => Math.round(jTime*24*60)})), Time.FORMAT_SHORT);		
		var t = sunInfo.hour*60 + sunInfo.min;
		
		// day_of_week is 1-7 (1=Sun, 2=Mon 3=Tue ...)
		// so subtract 1 before doing modulo, then add 1 again afterwards
		if (sunInfo.day_of_week==(nowDayOfWeek/*+1-1*/)%7+1)	// tomorrow
		{
			t += 24*60;
		}
		else if (sunInfo.day_of_week==(nowDayOfWeek+6-1)%7+1)	// yesterday
		{
			t -= 24*60;
		}
		return t;
	}

	// want to save:
	// profile active + end time
	// profile random + end time
	// demo profile + end time
	// position: latitude (double), longitude (double), altitude (float)
	//
	// save as separate properties? (string, number, float, boolean)
	(:m2face)
	function loadMemoryData(timeNowValue)
	{
		positionGot = propertiesGetBoolean("pg");
		positionLatitude = propertiesGetFloat("la"); 
		positionLongitude = propertiesGetFloat("lo");
		positionAltitude = propertiesGetFloat("al");

		var profileNumber;
		var profileEnd;

		profileNumber = propertiesGetNumber("ap");
		profileEnd = propertiesGetNumber("ae");
		if (profileNumber>=0 && profileNumber<PROFILE_NUM_USER+PROFILE_NUM_PRESET)
		{
			profileActive = profileNumber;
			// verify that profileDelayEnd is not too far in the future ... just in case (should be 2+1 minutes or less)
			profileDelayEnd = ((profileEnd <= (timeNowValue + (2+1)*60)) ? profileEnd : 0);
		}

		profileNumber = propertiesGetNumber("rp");
		profileEnd = propertiesGetNumber("re");
		if (profileNumber>=0 && profileNumber<PROFILE_NUM_USER+PROFILE_NUM_PRESET)
		{
			profileRandom = profileNumber;
			// verify that profileRandomEnd is not too far in the future ... just in case (should be 20+1 minutes or less)
			profileRandomEnd = ((profileEnd <= (timeNowValue + (20+1)*60)) ? profileEnd : 0);
		}

		demoProfilesOn = propertiesGetBoolean("do");
		profileNumber = propertiesGetNumber("dp");
		profileEnd = propertiesGetNumber("de");
		if (profileNumber>=0 && profileNumber<PROFILE_NUM_USER+PROFILE_NUM_PRESET)
		{
			demoProfilesCurrentProfile = profileNumber;
			// verify that demoProfilesCurrentEnd is not too far in the future ... just in case (should be 5+1 minutes or less)
			demoProfilesCurrentEnd = ((profileEnd <= (timeNowValue + (5+1)*60)) ? profileEnd : 0);
		}
	}
	
	(:m2face)
	function saveMemoryData()
	{
		applicationProperties.setValue("pg", positionGot);
		applicationProperties.setValue("la", positionLatitude);
		applicationProperties.setValue("lo", positionLongitude);
		applicationProperties.setValue("al", positionAltitude);

		applicationProperties.setValue("ap", profileActive);
		applicationProperties.setValue("ae", profileDelayEnd);

		applicationProperties.setValue("rp", profileRandom);
		applicationProperties.setValue("re", profileRandomEnd);

		applicationProperties.setValue("do", demoProfilesOn);
		applicationProperties.setValue("dp", demoProfilesCurrentProfile);
		applicationProperties.setValue("de", demoProfilesCurrentEnd);
	}

	(:m2app)
	function loadMemoryData(timeNowValue)
	{
		positionGot = propertiesGetBoolean("pg");
		positionLatitude = propertiesGetFloat("la"); 
		positionLongitude = propertiesGetFloat("lo");
		positionAltitude = propertiesGetFloat("al");
	}
	
	(:m2app)
	function saveMemoryData()
	{
		applicationProperties.setValue("pg", positionGot);
		applicationProperties.setValue("la", positionLatitude);
		applicationProperties.setValue("lo", positionLongitude);
		applicationProperties.setValue("al", positionAltitude);
	}
	
	// Time is stored as hour*60 + minutes - this has a maximum of 24*60 = 1,440 = 0x5A0 (11 bits 0x7FF)
	// start time (0-1440)
	// end time (0-1440)
	// days (0-128)
	// flags (start sunrise, start sunset, end sunrise, end sunset, block random)
	// random events (0-255)
	// glance profile (+1)
	//
	//const PROFILE_START_SUNRISE = 0x01;
	//const PROFILE_START_SUNSET = 0x02;
	//const PROFILE_END_SUNRISE = 0x04;
	//const PROFILE_END_SUNSET = 0x08;
	//const PROFILE_BLOCK_MASK = 0x10;			// block random
	var profileData = new[PROFILE_NUM_USER*6];
	
	(:m2face)
	function loadProfileData()
	{
		var charArray = propertiesGetCharArray("sd");

		valDecodeArray(profileData, PROFILE_NUM_USER*6, charArray, charArray.size());

		//System.println("profileData=" + profileData.toString());
	}
	
	(:m2face)
	function saveProfileData()
	{
		var tempCharArray = new[PROFILE_NUM_USER*6*2];
		valEncodeArray(profileData, PROFILE_NUM_USER*6, tempCharArray, PROFILE_NUM_USER*6*2);
		
		applicationProperties.setValue("sd", StringUtil.charArrayToString(tempCharArray));
	}

	(:m2app)
	function loadProfileData()
	{
	}
	
	(:m2app)
	function saveProfileData()
	{
	}
	
/*
	array of data
		item type
		item data
			{ field string: type, color, font, string start, string end, width }
			{ icon: }
			{ chart: }
			{ ring: ring identifier & font, start, end, start fill, end fill, col fill, col unfill }
			{ rectangle: }
			{ seconds: }
	char array - for calculated strings
*/
/*
	profile name
	
	<list of fonts & jsondata to load>
	
	watch display size
	background color
	default field color
	default date font
	default value font
	
	add leading zero
	
	override 2nd time zone offset
	move bar alert trigger level
	battery high percentage
	battery low percentage
*/	

	// id
	// 0 = header
	// 1 = field
	// 2 = hour large
	// 3 = minute large
	// 4 = colon large
	// 5 = string
	// 6 = icon
	// 7 = movebar
	// 8 = chart
	// 9 = rectangle
	// 10 = ring
	// 11 = seconds

	var gfxNum = 0;
	var gfxData = new[512];

	var gfxCharArray = new[256];
	var gfxCharArrayLen = 0;

	function valEncodeChar(v)
	{
		// 0-9 a-z A-Z
		// 10 +26 +26 =62
		// 62*62=3844, so 0-3843
		//
		// 0 = 48
		// A = 65
		// a = 97

		var c;
		if (v<10)
		{
			c = 48+v;
		}
		else if (v<36)
		{
			c = 65-10+v;
		}
		else //if (v<62)
		{
			c = 97-36+v;
		}
		
		return c.toChar();
	}		
	
	function valDecodeChar(c)
	{
		// 0-9 a-z A-Z
		// 10 +26 +26 =62
		// 62*62=3844, so 0-3843
		//
		// 0 = 48
		// A = 65
		// a = 97

		var v = c.toNumber();
		if (v>=97)
		{
			v -= (97-36);
		}
		else if (v>=65)
		{
			v -= (65-10);
		}
		else //if (v>=48)
		{
			v -= 48;
		}
		
		return v;
	}		
	
	function valEncodeArray(arr, arrSize, charArray, charArraySize)
	{
		for (var i=0; i<arrSize; i++)
		{
			// 0-9 a-z A-Z
			// 10 +26 +26 =62
			// 62*62=3844, so 0-3843
			
			var val = arr[i];
			if (val==null)
			{
				val = 0;
			}
			
			var v0 = val/62;
			var v1 = val%62;
			
			charArray[i*2] = valEncodeChar(v0);
			charArray[i*2 + 1] = valEncodeChar(v1);
		}
	}

	function valDecodeArray(arr, arrSize, charArray, charArraySize)
	{
		for (var i=0; i<arrSize; i++)
		{
			var v0 = 0;
			var v1 = 0;
			
			var i2 = i*2;
			if (i2 < charArraySize-1)
			{
				v0 = valDecodeChar(charArray[i2]);
				v1 = valDecodeChar(charArray[i2+1]);
			}
			
			arr[i] = v0*62 + v1;
		}
	}

	function gfxToCharArray()
	{
		var charArray = new[1024];
		var charArrayLen = 0;
	
		for (var index=0; index<gfxNum; )
		{
			var id = (gfxData[index] & 0xFF);
		
			var saveSize = gfxSizeSave(id);
			for (var i=0; i<saveSize; i++)
			{
				var val = gfxData[index+i] & 0xFFFF;
				
				// 0-9 a-z A-Z
				// 10 +26 +26 =62
				// 62*62=3844, so 0-3843
				
				// but use the top bit to indicate if it is 1 or 2 bytes (so half that range)
				
				var c;
				if (val<31)
				{
					c = valEncodeChar(val);
					charArray[charArrayLen] = c;
					charArrayLen++;
					//System.print("" + c.toString() + ", ");
				}
				else
				{
					var v0 = val/62 + 31;
					var v1 = val%62;
					
					c = valEncodeChar(v0);
					charArray[charArrayLen] = c;
					charArrayLen++;
					//System.print("" + c.toString() + ", ");

					c = valEncodeChar(v1);
					charArray[charArrayLen] = c;
					charArrayLen++;
					//System.print("" + c.toString() + ", ");
				}
			}		
		
			index += gfxSize(id);				
		}

		//System.println("");
		
		return charArray.slice(0, charArrayLen);
	}

	function gfxFromCharArray(charArray)
	{
		var charArraySize = charArray.size();

		gfxNum = 0;

		for (var index=0; index<charArraySize; )
		{
			var id = 0;
		
			var saveSize = 1;
			for (var i=0; i<saveSize; i++)
			{
				var v = valDecodeChar(charArray[index]);
				index++;

				if (v>=31)
				{
					var v1 = valDecodeChar(charArray[index]);
					index++;
					v = (v-31)*62 + v1;
				}

				gfxData[gfxNum + i] = v;

				//System.print("" + v + ", ");

				if (i==0)
				{
					id = (v & 0xFF);
					saveSize = gfxSizeSave(id);
				}
			}
			
			gfxNum += gfxSize(id);
		}

		//System.println("");
	}

	function gfxSize(id)
	{
		return [
			6,		// header
			6,		// field
			7,		// hour large
			7,		// minute large
			7,		// colon large
			7,		// string
			6,		// icon
			11,		// movebar
			5,		// chart
			6,		// rectangle
			8,		// ring
			2,		// seconds
		][id];
	}

	function gfxSizeSave(id)
	{
		return [
			6,		// header
			4,		// field
			3,		// hour large
			3,		// minute large
			3,		// colon large
			4,		// string
			4,		// icon
			9,		// movebar
			4,		// chart
			6,		// rectangle
			7,		// ring
			2,		// seconds
		][id];
	}

	function gfxAddHeader(index)
	{
		gfxData[index] = 0;		// id
		gfxData[index+1] = 0;	// version
		gfxData[index+2] = 0;	// watch display size
		gfxData[index+3] = 0;	// background color
		gfxData[index+4] = 0;	// default field color
		gfxData[index+5] = 0;	// default field font
	}

	function gfxAddField(index)
	{
		gfxData[index] = 1;		// id & visibility
		gfxData[index+1] = 0;	// x from left
		gfxData[index+2] = 0;	// y from bottom
		gfxData[index+3] = 0;	// justification (0==centre, 1==left, 2==right)
		// total width
		// x adjustment
	}

	function gfxAddHourLarge(index)
	{
		gfxData[index] = 2;		// id & visibility
		gfxData[index+1] = 3+1;	// color
		gfxData[index+2] = 0;	// font
		// string 0
		// width 0
		// string 1
		// width 1
	}

	function gfxAddMinuteLarge(index)
	{
		gfxData[index] = 3;		// id & visibility
		gfxData[index+1] = 3+1;	// color
		gfxData[index+2] = 0;	// font
		// string 0
		// width 0
		// string 1
		// width 1
	}

	function gfxAddColonLarge(index)
	{
		gfxData[index] = 4;		// id & visibility
		gfxData[index+1] = 3+1;	// color
		gfxData[index+2] = 0;	// font
		// string 0 dummy
		// width 0 dummy
		// string 1
		// width 1
	}

	function gfxAddString(index)
	{
		gfxData[index] = 5;		// id & visibility
		gfxData[index+1] = 0;	// type
		gfxData[index+2] = 3+1;	// color
		gfxData[index+3] = 0;	// font & makeUpperCase & diacritics
		// string start
		// string end
		// width
	}

	function gfxAddIcon(index)
	{
		gfxData[index] = 6;		// id & visibility
		gfxData[index+1] = 0;	// type
		gfxData[index+2] = 3+1;	// color
		gfxData[index+3] = 0;	// font
		// char
		// width
	}

	function gfxAddMoveBar(index)
	{
		gfxData[index] = 7;		// id & visibility
		gfxData[index+1] = 0;	// type
		gfxData[index+2] = 0;	// font
		gfxData[index+3] = 3+1;	// color 1
		gfxData[index+4] = 3+1;	// color 2
		gfxData[index+5] = 3+1;	// color 3
		gfxData[index+6] = 3+1;	// color 4
		gfxData[index+7] = 3+1;	// color 5
		gfxData[index+8] = 3+1;	// color off
		// level
		// width
	}

	function gfxAddChart(index)
	{
		gfxData[index] = 8;		// id & visibility
		gfxData[index+1] = 0;	// type
		gfxData[index+2] = 3+1;	// color chart
		gfxData[index+3] = 3+1;	// color axes
		// width
	}

	function gfxAddRectangle(index)
	{
		gfxData[index] = 9;		// id & visibility
		gfxData[index+1] = 3+1;	// color
		gfxData[index+2] = 0;	// x from left
		gfxData[index+3] = 0;	// y from bottom
		gfxData[index+4] = 0;	// width
		gfxData[index+5] = 0;	// height
	}

	function gfxAddRing(index)
	{
		gfxData[index] = 10;	// id & visibility
		gfxData[index+1] = 0;	// type & direction
		gfxData[index+2] = 0;	// font
		gfxData[index+3] = 0;	// start
		gfxData[index+4] = 59;	// end
		gfxData[index+5] = 3+1;	// color filled
		gfxData[index+6] = 0+1;	// color unfilled
		// start fill, end fill & no fill flag
	}

	function gfxAddSeconds(index)
	{
		gfxData[index] = 11;	// id & visibility
		gfxData[index+1] = 0;	// font & refresh style
	}

	function gfxDelete(index)
	{
		var id = (gfxData[index] & 0xFF);
		var size = gfxSize(id);
		for (var i=index+size; i<gfxNum; i++)
		{
			gfxData[i-size] = gfxData[i];
		}
		gfxNum -= size;
	}

	function gfxInsert(index, id)
	{
		var size = gfxSize(id);
		for (var i=gfxNum-1; i>=index; i--)
		{
			gfxData[i+size] = gfxData[i];
		}
		
		gfxData[index] = id;
		for (var i=index+1; i<index+size; i++)
		{
			gfxData[i] = 0;
		}
		
		gfxNum += size;
	}

	function gfxDemo()
	{
		propBackgroundColor = getColor64(0);
		propAddLeadingZero = false;
		propFieldFontSystemCase = 0;		// get case for system fonts
    	propFieldFontUnsupported = 0;		
    	propMoveBarAlertTriggerLevel = 0;
	    propBatteryHighPercentage = 75;
	    propBatteryLowPercentage = 25;
		prop2ndTimeZoneOffset = 0;

		gfxCharArrayLen = 0;

		gfxNum = 0;
		
		gfxInsert(gfxNum, 0);	// header	

		gfxInsert(gfxNum, 1);	// field	
		gfxInsert(gfxNum, 2);	// large hour 
		gfxInsert(gfxNum, 4);	// large colon
		gfxInsert(gfxNum, 3);	// large minute

		gfxInsert(gfxNum, 1);	// field
		gfxInsert(gfxNum, 5);	// string
		//gfxInsert(gfxNum, 6);	// icon
		//gfxInsert(gfxNum, 7);	// movebar
		gfxInsert(gfxNum, 8);	// chart

		gfxInsert(gfxNum, 1);	// field
		gfxInsert(gfxNum, 10);	// ring

		gfxInsert(gfxNum, 9);	// rectangle

		gfxInsert(gfxNum, 11);	// seconds

		for (var index=0; index<gfxNum; )
		{
			var id = (gfxData[index] & 0xFF);
			
			switch(id)
			{
				case 0:		// header
				{
					break;
				}
				
				case 1:		// field
				{
					gfxData[index+1] = 120;	// x from left
					gfxData[index+2] = 120;	// y from bottom
					gfxData[index+3] = 0;	// justification (0==centre, 1==left, 2==right)
					break;
				}
				
				case 2:		// hour large
				case 3:		// minute large
				case 4:		// colon large
				{
					gfxData[index+1] = 3+1;	// color
					gfxData[index+2] = 0/*APPFONT_ULTRA_LIGHT*/;	// font

					//gfxData[index+2] = 24/*APPFONT_SYSTEM_XTINY*/;	// font
					//gfxData[index+2] = 32/*APPFONT_SYSTEM_NUMBER_HUGE*/;	// font
					//if (id==2)
					//{
						//gfxData[index+2] = 0;	// ascent 62
						//gfxData[index+2] = 6;	// ascent 18
						//gfxData[index+2] = 12;	// ascent 22
						//gfxData[index+2] = 18;	// ascent 27
						//gfxData[index+2] = 24;	// font
						//gfxData[index+2] = 32;	// font
					//}
					
					break;
				}

				case 5:		// string
				{
					gfxData[index+1] = 3/*FIELD_DAY_NAME*/;		// type
					gfxData[index+2] = 3+1;	// color
					gfxData[index+3] = 15/*APPFONT_REGULAR_SMALL*/;	// font
					
					break;
				}
				
				case 6:		// icon
				{
					gfxData[index+1] = 0;	// type
					gfxData[index+2] = 3+1;	// color
					gfxData[index+3] = 0;	// font

					break;
				}
				
				case 7:		// movebar
				{
					gfxData[index+1] = 0;	// type
					gfxData[index+2] = 0;	// font
					gfxData[index+3] = 3+1;	// color 1
					gfxData[index+4] = 3+1;	// color 2
					gfxData[index+5] = 3+1;	// color 3
					gfxData[index+6] = 3+1;	// color 4
					gfxData[index+7] = 3+1;	// color 5
					gfxData[index+8] = COLOR_NOTSET+1;	// color off

					break;
				}
				
				case 8:		// chart
				{
					gfxData[index+1] = 0;	// type
					gfxData[index+2] = 3+1;	// color chart
					gfxData[index+3] = 3+1;	// color axes

					break;
				}
				
				case 9:		// rectangle
				{
					gfxData[index+1] = 6+1;	// color
					gfxData[index+2] = 70;	// x from left
					gfxData[index+3] = 170;	// y from bottom
					gfxData[index+4] = 1;	// width
					gfxData[index+5] = 50;	// height
					
					break;
				}
				
				case 10:	// ring
				{
					gfxData[index+1] = 0;	// type & direction
					gfxData[index+2] = 0;	// font
					gfxData[index+3] = 0;	// start
					gfxData[index+4] = 59;	// end
					gfxData[index+5] = 3+1;	// color filled
					gfxData[index+6] = 0+1;	// color unfilled

					break;
				}
				
				case 11:	// seconds
				{
					gfxData[index+1] = 0;	// font
					gfxData[index+1] |= (0 << 8);	// refresh style
					
					break;
				}
			}
			
			index += gfxSize(id);
		}

		//gfxToCharArray();
		//System.println("array=" + StringUtil.charArrayToString(gfxCharArray.slice(0, gfxCharArrayLen)));
		//gfxFromCharArray();
		//gfxToCharArray();
		//System.println("arra2=" + StringUtil.charArrayToString(gfxCharArray.slice(0, gfxCharArrayLen)));
	}
	
	// seconds, ring, hour, minute, icon, field
	const MAX_DYNAMIC_RESOURCES = 16;
	
	var dynResNum = 0;
	var dynResList = new[MAX_DYNAMIC_RESOURCES];
	var dynResResource = new[MAX_DYNAMIC_RESOURCES];

	function addDynamicResource(r)
	{
		for (var i=0; i<dynResNum; i++)
		{
			if (r==dynResList[i])
			{
				return i;
			}
		}
		
		if (dynResNum < MAX_DYNAMIC_RESOURCES)
		{
			dynResList[dynResNum] = r;
			dynResNum++;
			
			return dynResNum-1;
		}
		
		return MAX_DYNAMIC_RESOURCES;
	}

	function getDynamicResource(i)
	{
		return ((i<dynResNum) ? dynResResource[i] : null);
	}

    function releaseDynamicResources()
    {
		for (var i=0; i<dynResNum; i++)
		{
			dynResResource[i] = null;
		}
		
		dynResNum = 0;
    }

    function loadDynamicResources()
    {
		for (var i=0; i<dynResNum; i++)
		{
			var r = dynResList[i];
			dynResResource[i] = (isDynamicResourceSystemFont(i) ? r : WatchUi.loadResource(r));
		}
    }
    
    function isDynamicResourceSystemFont(i)
    {
    	return ((i<dynResNum) && (dynResList[i]<=Graphics.FONT_SYSTEM_NUMBER_THAI_HOT));
    }

	function gfxLoadDynamicResources()
	{
		gfxDemo();
	
    	var fonts = Rez.Fonts;
		var graphics = Graphics;

    	propSecondIndicatorOn = false;
    	
		var fontList = [
			fonts.id_trivial_ultra_light,		// APPFONT_ULTRA_LIGHT
			fonts.id_trivial_extra_light,		// APPFONT_EXTRA_LIGHT
			fonts.id_trivial_light,				// APPFONT_LIGHT
			fonts.id_trivial_regular,			// APPFONT_REGULAR
			fonts.id_trivial_bold,				// APPFONT_BOLD
			fonts.id_trivial_heavy,				// APPFONT_HEAVY

			fonts.id_trivial_ultra_light_tiny,	// APPFONT_ULTRA_LIGHT_TINY
			fonts.id_trivial_extra_light_tiny,	// APPFONT_EXTRA_LIGHT_TINY
			fonts.id_trivial_light_tiny,		// APPFONT_LIGHT_TINY
			fonts.id_trivial_regular_tiny,		// APPFONT_REGULAR_TINY
			fonts.id_trivial_bold_tiny,			// APPFONT_BOLD_TINY
			fonts.id_trivial_heavy_tiny,		// APPFONT_HEAVY_TINY
			fonts.id_trivial_ultra_light_small,	// APPFONT_ULTRA_LIGHT_SMALL
			fonts.id_trivial_extra_light_small,	// APPFONT_EXTRA_LIGHT_SMALL
			fonts.id_trivial_light_small,		// APPFONT_LIGHT_SMALL
			fonts.id_trivial_regular_small,		// APPFONT_REGULAR_SMALL
			fonts.id_trivial_bold_small,		// APPFONT_BOLD_SMALL
			fonts.id_trivial_heavy_small,		// APPFONT_HEAVY_SMALL
			fonts.id_trivial_ultra_light_medium,// APPFONT_ULTRA_LIGHT_MEDIUM
			fonts.id_trivial_extra_light_medium,// APPFONT_EXTRA_LIGHT_MEDIUM
			fonts.id_trivial_light_medium,		// APPFONT_LIGHT_MEDIUM
			fonts.id_trivial_regular_medium,	// APPFONT_REGULAR_MEDIUM
			fonts.id_trivial_bold_medium,		// APPFONT_BOLD_MEDIUM
			fonts.id_trivial_heavy_medium,		// APPFONT_HEAVY_MEDIUM

			graphics.FONT_SYSTEM_XTINY, 			// APPFONT_SYSTEM_XTINY
			graphics.FONT_SYSTEM_TINY, 				// APPFONT_SYSTEM_TINY
			graphics.FONT_SYSTEM_SMALL, 			// APPFONT_SYSTEM_SMALL
			graphics.FONT_SYSTEM_MEDIUM,			// APPFONT_SYSTEM_MEDIUM
			graphics.FONT_SYSTEM_LARGE,				// APPFONT_SYSTEM_LARGE
			graphics.FONT_SYSTEM_NUMBER_MILD,		// APPFONT_SYSTEM_NUMBER_NORMAL 
			graphics.FONT_SYSTEM_NUMBER_MEDIUM,		// APPFONT_SYSTEM_NUMBER_MEDIUM 
			graphics.FONT_SYSTEM_NUMBER_HOT,		// APPFONT_SYSTEM_NUMBER_LARGE 
			graphics.FONT_SYSTEM_NUMBER_THAI_HOT,	// APPFONT_SYSTEM_NUMBER_HUGE 

			fonts.id_trivial_ultra_light_italic,	// APPFONT_ULTRA_LIGHT
			fonts.id_trivial_extra_light_italic,	// APPFONT_EXTRA_LIGHT
			fonts.id_trivial_light_italic,			// APPFONT_LIGHT
			fonts.id_trivial_regular_italic,		// APPFONT_REGULAR
			fonts.id_trivial_bold_italic,			// APPFONT_BOLD
			fonts.id_trivial_heavy_italic,			// APPFONT_HEAVY
		];
				
		var secondFontList = [
			fonts.id_seconds_tri,			// SECONDFONT_TRI
			fonts.id_seconds_v,				// SECONDFONT_V
			fonts.id_seconds_line,			// SECONDFONT_LINE
			fonts.id_seconds_linethin,		// SECONDFONT_LINETHIN
			fonts.id_seconds_circular,		// SECONDFONT_CIRCULAR
			fonts.id_seconds_circularthin,	// SECONDFONT_CIRCULARTHIN
			
			fonts.id_seconds_tri_in,		// SECONDFONT_TRI_IN
			fonts.id_seconds_v_in,			// SECONDFONT_V_IN
			fonts.id_seconds_line_in,		// SECONDFONT_LINE_IN
			fonts.id_seconds_linethin_in,	// SECONDFONT_LINETHIN_IN
			fonts.id_seconds_circular_in,	// SECONDFONT_CIRCULAR_IN
			fonts.id_seconds_circularthin_in,	// SECONDFONT_CIRCULARTHIN_IN
		];

		var iconFontList = [
			fonts.id_icons,
		];

		var ringFontList = [
			fonts.id_outer,
		];
		
		for (var index=0; index<gfxNum; )
		{
			var id = (gfxData[index] & 0xFF);
			
			switch(id)
			{
				case 0:		// header
				{
					break;
				}
				
				case 1:		// field
				{
					break;
				}
				
				case 2:		// hour large
				case 3:		// minute large
				case 4:		// colon large
				{
					var r = (gfxData[index+2] & 0xFF);
				 	if (r<0 || r>38)
				 	{
				 		r = 3/*APPFONT_REGULAR*/;
				 	}
					var resourceIndex = addDynamicResource(fontList[r]);
					
					gfxData[index+2] |= ((resourceIndex & 0xFF) << 16);
					gfxData[index+2] |= ((r & 0xFF) << 24);		// fontTypeKern

					break;
				}

				case 5:		// string
				{
					var r = (gfxData[index+3] & 0xFF);
				 	if (r<0 || r>38)
				 	{
				 		r = 15/*APPFONT_REGULAR_SMALL*/;
				 	}
					var resourceIndex = addDynamicResource(fontList[r]);
					
					gfxData[index+3] |= ((resourceIndex & 0xFF) << 16);

					break;
				}
				
				case 6:		// icon
				{
					var resourceIndex = addDynamicResource(iconFontList[0]);
					
					gfxData[index+3] |= ((resourceIndex & 0xFF) << 16);

					break;
				}
				
				case 7:		// movebar
				{
					var resourceIndex = addDynamicResource(iconFontList[0]);
					
					gfxData[index+2] |= ((resourceIndex & 0xFF) << 16);

					break;
				}
				
				case 8:		// chart
				{
					break;
				}
				
				case 9:		// rectangle
				{
					break;
				}
				
				case 10:	// ring
				{
					var resourceIndex = addDynamicResource(ringFontList[0]);
					
					gfxData[index+2] |= ((resourceIndex & 0xFF) << 16);

					break;
				}
				
				case 11:	// seconds
				{
			    	//gfxData[index+1] |= 0x80000000; 	// move in a bit - set depending on what the font is

					// calculate the seconds color array
			    	var secondColorIndex = 3;		// second color
			    	var secondColorIndex5 = COLOR_NOTSET;
			    	var secondColorIndex10 = COLOR_NOTSET;
			    	var secondColorIndex15 = COLOR_NOTSET;
			    	var secondColorIndex0 = COLOR_NOTSET;
			    	var secondColorDemo = false;		// second color demo
			    	
			    	for (var i=0; i<60; i++)
			    	{
						var col;
				
				        if (secondColorDemo)		// second color demo
				        {
				        	col = 4 + i;
				        }
						else if (secondColorIndex0!=COLOR_NOTSET && i==0)
						{
							col = secondColorIndex0;
						}
						else if (secondColorIndex15!=COLOR_NOTSET && (i%15)==0)
						{
							col = secondColorIndex15;
						}
						else if (secondColorIndex10!=COLOR_NOTSET && (i%10)==0)
						{
							col = secondColorIndex10;
						}
						else if (secondColorIndex5!=COLOR_NOTSET && (i%10)==5)
						{
							col = secondColorIndex5;
						}
				        else
				        {
				        	col = secondColorIndex;		// second color
				        }
				        
				        secondsColorIndexArray[i] = col;
				    }
			
					//this test code now works out exactly the same size as the original above!
					//// Initialising the array like this works out 100 bytes more expensive
					////var colArray = [propertiesGetColorIndex("13", 0), 4, propertiesGetColorIndex("17", -1), propertiesGetColorIndex("16", -1), propertiesGetColorIndex("15", -1), propertiesGetColorIndex("14", -1)];			
					//var colArray = new [6];
					//colArray[0] = propertiesGetColorIndex("13", 0);
					//for (var i=2; i<6; i++)
					//{
					//	colArray[i] = propertiesGetColorIndex("" + (19-i), -1);
					//}			
					//var secondColorDemo2 = propertiesGetBoolean("18");		// second color demo
					//
					//// this for loop is 30 bytes cheaper than original
					//for (var i=0; i<60; i++)
					//{
					//	colArray[1] = 4+i;
					//	var testArray = [secondColorDemo2, i==0 && colArray[2]!=-1, (i%15)==0 && colArray[3]!=-1, (i%10)==0 && colArray[4]!=-1, (i%10)==5 && colArray[5]!=-1];
					//	secondsColorIndexArray[i] = colArray[testArray.indexOf(true)+1];
					//}		
					
					var r = (gfxData[index+1] & 0xFF);
				 	if (r<0 || r>=12/*SECONDFONT_UNUSED*/)
				 	{
				 		r = 0/*SECONDFONT_TRI*/;
				 	}
					var resourceIndex = addDynamicResource(secondFontList[r]);
					
					gfxData[index+1] |= ((resourceIndex & 0xFF) << 16);
					
					break;
				}
			}
			
			index += gfxSize(id);
		}
	}
	
	function getSunOuterFill(t, timeOffsetInMinutes, segmentAdjust, drawRange)
	{
		//return ((((t!=null) ? t : 0) + 12 + 24*60 - timeOffsetInMinutes) / 24 + segmentAdjust + 60)%60;
		return (((((t!=null) ? t : 0) + 12 + 24*60 - timeOffsetInMinutes) * drawRange) / (24*60) + segmentAdjust + drawRange)%drawRange;
	}

	function gfxOnUpdate(dc, clockTime, timeNow)
	{
        var hour = clockTime.hour;
        var minute = clockTime.min;
        var second = clockTime.sec;
        var timeNowInMinutesToday = hour*60 + minute;

        var deviceSettings = System.getDeviceSettings();		// 960 bytes, but uses less code memory
		var activityMonitorInfo = ActivityMonitor.getInfo();  	// 560 bytes, but uses less code memory
		var systemStats = System.getSystemStats();				// 168 bytes, but uses less code memory
        var firstDayOfWeek = deviceSettings.firstDayOfWeek;
		var gregorian = Time.Gregorian;
		var dateInfoShort = gregorian.info(timeNow, Time.FORMAT_SHORT);
		var dateInfoMedium = gregorian.info(timeNow, Time.FORMAT_MEDIUM);
		var dayNumberOfWeek = (((dateInfoShort.day_of_week - firstDayOfWeek + 7) % 7) + 1);		// 1-7
		var hour2nd = (hour - clockTime.timeZoneOffset/3600 + prop2ndTimeZoneOffset + 24)%24;		// 2nd time zone

        // Get the current time and format it correctly
    	var hourString = formatHourForDisplayString(hour, deviceSettings.is24Hour, propAddLeadingZero);
        var minuteString = minute.format("%02d");

		var activityMonitorSteps = getNullCheckZero(activityMonitorInfo.steps);
		var activityMonitorStepGoal = getNullCheckZero(activityMonitorInfo.stepGoal);
		var activityMonitorActiveMinutesWeekTotal = ((activityMonitorInfo.activeMinutesWeek!=null) ? activityMonitorInfo.activeMinutesWeek.total : 0);
		var activityMonitorActiveMinutesWeekGoal = getNullCheckZero(activityMonitorInfo.activeMinutesWeekGoal);
		var activeMinutesWeekSmartGoal = ((activityMonitorActiveMinutesWeekGoal * dayNumberOfWeek) / 7);

		// calculate fields to display
		var visibilityStatus = new[25/*STATUS_NUM*/];
		visibilityStatus[0/*STATUS_ALWAYSON*/] = true;
	    visibilityStatus[1/*STATUS_DONOTDISTURB_ON*/] = (hasDoNotDisturb && deviceSettings.doNotDisturb);
	    visibilityStatus[2/*STATUS_DONOTDISTURB_OFF*/] = (hasDoNotDisturb && !deviceSettings.doNotDisturb);
	    var alarmCount = deviceSettings.alarmCount;
	    visibilityStatus[3/*STATUS_ALARM_ON*/] = (alarmCount > 0);
	    visibilityStatus[4/*STATUS_ALARM_OFF*/] = (alarmCount == 0);
	    var notificationCount = deviceSettings.notificationCount;
	    visibilityStatus[5/*STATUS_NOTIFICATIONS_PENDING*/] = (notificationCount > 0);
	    visibilityStatus[6/*STATUS_NOTIFICATIONS_NONE*/] = (notificationCount == 0);
	    var phoneConnected = deviceSettings.phoneConnected;
	    visibilityStatus[7/*STATUS_PHONE_CONNECTED*/] = phoneConnected;
	    visibilityStatus[8/*STATUS_PHONE_NOT*/] = !phoneConnected;
	    var lteState = lteConnected();
	    visibilityStatus[9/*STATUS_LTE_CONNECTED*/] = (hasLTE && lteState);
	    visibilityStatus[10/*STATUS_LTE_NOT*/] = (hasLTE && !lteState);
	    var batteryLevel = systemStats.battery;
	    visibilityStatus[12/*STATUS_BATTERY_HIGH*/] = (batteryLevel>=propBatteryHighPercentage);
	    visibilityStatus[14/*STATUS_BATTERY_LOW*/] = (!visibilityStatus[12/*STATUS_BATTERY_HIGH*/] && batteryLevel<=propBatteryLowPercentage);
	    visibilityStatus[13/*STATUS_BATTERY_MEDIUM*/] = (!visibilityStatus[12/*STATUS_BATTERY_HIGH*/] && !visibilityStatus[14/*STATUS_BATTERY_LOW*/]);
	    visibilityStatus[11/*STATUS_BATTERY_HIGHORMEDIUM*/] = !visibilityStatus[14/*STATUS_BATTERY_LOW*/];
		// moveBarLevel 0 = not triggered
		// moveBarLevel has range 1 to 5
		// propFieldMoveAlarmTriggerTime has range 1 to 5
		var activityTrackingOn = deviceSettings.activityTrackingOn;
		var activityMonitorMoveBarLevel = getNullCheckZero(activityMonitorInfo.moveBarLevel);
	    var moveBarAlertTriggered = (activityMonitorMoveBarLevel >= propMoveBarAlertTriggerLevel); 
	    visibilityStatus[15/*STATUS_MOVEBARALERT_TRIGGERED*/] = (activityTrackingOn && moveBarAlertTriggered);
	    visibilityStatus[16/*STATUS_MOVEBARALERT_NOT*/] = (activityTrackingOn && !moveBarAlertTriggered);
	    visibilityStatus[17/*STATUS_AM*/] = (hour < 12);
	    visibilityStatus[18/*STATUS_PM*/] = (hour >= 12);
	    visibilityStatus[19/*STATUS_2ND_AM*/] = (hour2nd < 12);
	    visibilityStatus[20/*STATUS_2ND_PM*/] = (hour2nd >= 12);
	    visibilityStatus[21/*STATUS_SUNEVENT_RISE*/] = null;	// calculated on demand
	    visibilityStatus[22/*STATUS_SUNEVENT_SET*/] = null;		// calculated on demand
	    visibilityStatus[23/*STATUS_GLANCE_ON*/] = glanceActive;
	    visibilityStatus[24/*STATUS_GLANCE_OFF*/] = !glanceActive;

		fieldActivePhoneStatus = null;
		fieldActiveNotificationsStatus = null;
		fieldActiveNotificationsCount = null;
		fieldActiveLTEStatus = null;
		
		var indexCurField = -1;
		var fieldVisible = false;
		
		var indexPrevLargeWidth = -1;
		var prevLargeNumber = -1;
		var prevLargeFontKern = -1;
	
		gfxCharArrayLen = 0;
	
		for (var index=0; index<gfxNum; )
		{
			var id = (gfxData[index] & 0xFF);
			var eVisible = ((gfxData[index] >> 8) & 0xFF);

			var isVisible = true;
			
			if (eVisible>=0 && eVisible<25/*STATUS_NUM*/)
			{
				isVisible = visibilityStatus[eVisible];

				// these fieldActiveXXXStatus flags need setting whether or not the field element using them is visible!!
				// So make sure to do these tests before the visibility test
				if (eVisible==5/*STATUS_NOTIFICATIONS_PENDING*/ || eVisible==6/*STATUS_NOTIFICATIONS_NONE*/)
				{
					fieldActiveNotificationsStatus = (notificationCount > 0);
				} 
				if (eVisible==7/*STATUS_PHONE_CONNECTED*/ || eVisible==8/*STATUS_PHONE_NOT*/)
				{
					fieldActivePhoneStatus = phoneConnected;
				} 
				if (eVisible==9/*STATUS_LTE_CONNECTED*/ || eVisible==10/*STATUS_LTE_NOT*/)
				{
					fieldActiveLTEStatus = lteState;
				}

				isVisible = getVisibilityStatus(visibilityStatus, eVisible, dateInfoShort);
			}
			
			// remember visibility for this update
			if (isVisible)
			{
				gfxData[index] |= 0x10000;
			}
			else
			{
				gfxData[index] &= ~0x10000;
			}
			
			switch(id)
			{
				case 0:		// header
				{
					break;
				}

				case 1:		// field
				{
        			//System.println("gfxOnUpdate field");

					indexCurField = index;
					fieldVisible = isVisible;

					gfxData[index+4] = 0;	// total width
					gfxData[index+5] = 0;	// no x adjustment yet
					
					break;
				}

				case 2:		// hour large
				case 3:		// minute large
				case 4:		// colon large
				{
        			//System.println("gfxOnUpdate large");
				
					if (!(fieldVisible && isVisible))
					{
						break;
					}
					
					var resourceIndex = ((gfxData[index+2] >> 16) & 0xFF);
					var dynamicResource = getDynamicResource(resourceIndex);
					if (dynamicResource==null)
					{
						gfxData[index+3] = 0;	// width 0
						gfxData[index+4] = 0;	// width 0
						break;
					}
					
					var fontTypeKern = ((gfxData[index+2] >> 24) & 0xFF);

					var charArray;
					if (id==2)
					{
						charArray = hourString.toCharArray();
					}
					else if (id==3)
					{
						charArray = minuteString.toCharArray();
					}
					else //if (id==4)
					{
						charArray = ":".toCharArray();
					}
					
					var charArraySize = charArray.size();
					var charArrayIndex = 0;

					if (charArraySize==1)
					{
						//gfxData[index+3] = 0;	// string 0
						gfxData[index+4] = 0;	// width 0
					}
					else
					{
						var c = charArray[charArrayIndex];
						charArrayIndex++;
						gfxData[index+3] = c;	// string 0
						gfxData[index+4] = dc.getTextWidthInPixels(c.toString(), dynamicResource);	// width 0
						gfxData[indexCurField+4] += gfxData[index+4];	// total width
						
						if (indexPrevLargeWidth>=0)
						{
							var k = getKern(prevLargeNumber - 48/*APPCHAR_0*/, c.toNumber() - 48/*APPCHAR_0*/, prevLargeFontKern, fontTypeKern, false);
							gfxData[indexPrevLargeWidth] -= k;
							gfxData[indexCurField+4] -= k;	// total width
						}
						
						indexPrevLargeWidth = index+4;
						prevLargeNumber = c.toNumber();
						prevLargeFontKern = fontTypeKern;
					}

					{
						var c = charArray[charArrayIndex];
						gfxData[index+5] = c;	// string 1
						gfxData[index+6] = dc.getTextWidthInPixels(c.toString(), dynamicResource);	// width 1
						gfxData[indexCurField+4] += gfxData[index+6];	// total width
	
						if (indexPrevLargeWidth>=0)
						{
							var k = getKern(prevLargeNumber - 48/*APPCHAR_0*/, c.toNumber() - 48/*APPCHAR_0*/, prevLargeFontKern, fontTypeKern, false);
							gfxData[indexPrevLargeWidth] -= k;
							gfxData[indexCurField+4] -= k;	// total width
						}

						indexPrevLargeWidth = index+6;
						prevLargeNumber = c.toNumber();
						prevLargeFontKern = fontTypeKern;
						
						gfxData[indexCurField+5] = 0;	// remove existing x adjustment
						if (gfxData[indexCurField+3]==0)	// centre justification
						{
							//if (italic font)
							//{
							//	gfxData[indexCurField+5] += 1;	// shift right 1 pixel
							//}
							
							if ((c.toNumber() - 48/*APPCHAR_0*/) == 4)		// last digit is a 4 
							{
								gfxData[indexCurField+5] += 1;	// shift right 1 more pixel
							}
						}
					}
					
					break;
				}
				
				case 5:		// string
				{
					if (!(fieldVisible && isVisible))
					{
						break;
					}

					gfxData[index+4] = 0;	// string start
					gfxData[index+5] = 0;	// string end
					gfxData[index+6] = 0;	// width

					var resourceIndex = ((gfxData[index+3] >> 16) & 0xFF);

					var eStr = null;
					var eDisplay = gfxData[index+1];
					var makeUpperCase = false;
					var checkDiacritics = false;
					var useUnsupportedFont = false;
					
					switch(eDisplay)	// type of string
					{
						case 1/*FIELD_HOUR*/:			// hour
					    {
							eStr = hourString;
							break;
						}
	
						case 2/*FIELD_MINUTE*/:			// minute
					    {
							eStr = minuteString;
							break;
						}
	
						case 3/*FIELD_DAY_NAME*/:		// day name
						case 9/*FIELD_MONTH_NAME*/:		// month name
					    {
							eStr = ((eDisplay==3/*FIELD_DAY_NAME*/) ? dateInfoMedium.day_of_week : dateInfoMedium.month);

							//eStr = "\u0158\u015a\u00c7Z\u0179\u0104";		// test string for diacritics & bounding rectangle (use system large)
							//eStr = "A\u042d\u03b8\u05e9\u069b";			// test string for other languages (unsupported)

							if (isDynamicResourceSystemFont(resourceIndex))
							{
								// can display all diacritics
								// can display upper & lower case
							
								//if (propFieldFontSystemCase==1)	// APPCASE_UPPER = 1
								//{
								//	makeUpperCase = true;
								//}
								//else if (propFieldFontSystemCase==2)	// APPCASE_LOWER = 2
								//{
								//	eStr = eStr.toLower();
								//}
							}
							else
							{
								if (useUnsupportedFieldFont(eStr))
								{
									useUnsupportedFont = true;

									// will be using system font - so use case for that as specified by user
									//if (propFieldFontSystemCase==1)	// APPCASE_UPPER = 1
									//{
									//	makeUpperCase = true;
									//}
									//else if (propFieldFontSystemCase==2)	// APPCASE_LOWER = 2
									//{
									//	eStr = eStr.toLower();
									//}
								}
								else
								{
									checkDiacritics = true;
									makeUpperCase = true;
								}
							}
							
							break;
						}

						case 4/*FIELD_DAY_OF_WEEK*/:			// day number of week
					    {
							eStr = "" + dayNumberOfWeek;	// 1-7
							break;
						}
	
						case 5/*FIELD_DAY_OF_MONTH*/:			// day number of month
					    {
							eStr = "" + dateInfoMedium.day;
							break;
						}
	
						case 6/*FIELD_DAY_OF_MONTH_XX*/:			// day number of month XX
					    {
							eStr = dateInfoMedium.day.format("%02d");
							break;
						}
	
						case 7/*FIELD_DAY_OF_YEAR*/:				// day number of year
						case 8/*FIELD_DAY_OF_YEAR_XXX*/:			// day number of year XXX
						{
							calculateDayWeekYearData(0, firstDayOfWeek, dateInfoMedium);

    						eStr = dayOfYear.format((eDisplay == 7/*FIELD_DAY_OF_YEAR*/) ? "%d" : "%03d");        					
        					break;
        				}

						case 10/*FIELD_MONTH_OF_YEAR*/:		// month number of year
					    {
							eStr = "" + dateInfoShort.month;
							break;
						}
	
						case 11/*FIELD_MONTH_OF_YEAR_XX*/:			// month number of year XX
					    {
							eStr = dateInfoShort.month.format("%02d");
							break;
						}
	
						case 12/*FIELD_YEAR_XX*/:		// year XX
						{
							eStr = (dateInfoMedium.year % 100).format("%02d");
							break;
						}
	
						case 13/*FIELD_YEAR_XXXX*/:		// year XXXX
					    {
							eStr = "" + dateInfoMedium.year;
							break;
						}

						case 14/*FIELD_WEEK_ISO_XX*/:			// week number of year XX
						case 15/*FIELD_WEEK_ISO_WXX*/:		// week number of year WXX
						case 16/*FIELD_YEAR_ISO_WEEK_XXXX*/:
						{
							calculateDayWeekYearData(1, firstDayOfWeek, dateInfoMedium);							
						
							if (eDisplay == 16/*FIELD_YEAR_ISO_WEEK_XXXX*/)
							{
	        					eStr = "" + ISOYear;
							}
							else
							{
	        					eStr = ((eDisplay == 14/*FIELD_WEEK_ISO_XX*/) ? "" : "W") + ISOWeek.format("%02d");
	        				}
    						break;
						}
	
						case 17/*FIELD_WEEK_CALENDAR_XX*/:			// week number of year XX
						case 18/*FIELD_YEAR_CALENDAR_WEEK_XXXX*/:
						{
							calculateDayWeekYearData(2, firstDayOfWeek, dateInfoMedium);							
						    eStr = ((eDisplay==17/*FIELD_WEEK_CALENDAR_XX*/) ? CalendarWeek.format("%02d") : "" + CalendarYear);
							break;
						}
	
						case 19/*FIELD_AM*/:
					    {
							eStr = "AM";
							break;
						}
	
						case 20/*FIELD_PM*/:
					    {
							eStr = "PM";
							break;
						}
	
					    case 21/*FIELD_SEPARATOR_SPACE*/:
					    case 22:
					    case 23:
					    case 24:
					    case 25:
					    case 26:
					    case 27:
					    case 28/*FIELD_SEPARATOR_PERCENT*/:
					    {
							var separatorString = " /\\:-.,%";
		        			eStr = separatorString.substring(eDisplay-21/*FIELD_SEPARATOR_SPACE*/, eDisplay-21/*FIELD_SEPARATOR_SPACE*/+1);
		        			break;
					    }

						case 31/*FIELD_STEPSCOUNT*/:
						{
							eStr = "" + activityMonitorSteps;
							break;
						}

						case 32/*FIELD_STEPSGOAL*/:
						{
							eStr = "" + activityMonitorStepGoal;
							break;
						}

						case 33/*FIELD_FLOORSCOUNT*/:
						{
							eStr = "" + getNullCheckZero(activityMonitorInfo.floorsClimbed);
							break;
						}

						case 34/*FIELD_FLOORSGOAL*/:
						{
							eStr = "" + getNullCheckZero(activityMonitorInfo.floorsClimbedGoal);
							break;
						}

						case 35/*FIELD_NOTIFICATIONSCOUNT*/:
						{
							fieldActiveNotificationsCount = deviceSettings.notificationCount; 
							eStr = "" + fieldActiveNotificationsCount;
							break;
						}
						
						case 36/*FIELD_BATTERYPERCENTAGE*/:
						{
							eStr = "" + systemStats.battery.toNumber();
							break;
						}
						
						case 76/*FIELD_HEART_MIN*/:
						case 77/*FIELD_HEART_MAX*/:
						case 78/*FIELD_HEART_AVERAGE*/:
						case 79/*FIELD_HEART_LATEST*/:
						{
							calculateHeartRate(minute, second);

							var heartVal = (eDisplay==79/*FIELD_HEART_LATEST*/) ? heartDisplayLatest : 
										((eDisplay==76/*FIELD_HEART_MIN*/) ? heartDisplayMin : ((eDisplay==77/*FIELD_HEART_MAX*/) ? heartDisplayMax : heartDisplayAverage));
							eStr = (heartVal!=null) ? heartVal.format("%d") : "--";
							break;
						}

						case 82/*FIELD_SUNRISE_HOUR*/:
						case 83/*FIELD_SUNRISE_MINUTE*/:
						case 84/*FIELD_SUNSET_HOUR*/:
						case 85/*FIELD_SUNSET_MINUTE*/:
						case 86/*FIELD_SUNEVENT_HOUR*/:
						case 87/*FIELD_SUNEVENT_MINUTE*/:
						{
							calculateSun(dateInfoShort);

							var t = null;
							if (eDisplay>=86/*FIELD_SUNEVENT_HOUR*/)	// next sun event?
							{
								t = sunTimes[6];	// null or time of next sun event
							}
							else
							{
								// sunrise or sunset today
								t = ((eDisplay<=83/*FIELD_SUNRISE_MINUTE*/) ? sunTimes[0] : sunTimes[1]);
							}
																	
							if (t!=null)
							{
								t += 24*60;		// add 24 hours to make sure it is a positive number (if sunrise was before midnight ...) 
								if ((eDisplay-82/*FIELD_SUNRISE_HOUR*/)%2==1)
								{
									eStr = (t%60).format("%02d");		// minutes
								}
								else
								{
									eStr = formatHourForDisplayString((t/60)%24, deviceSettings.is24Hour, propAddLeadingZero);	// hours
								}
							}
							else
							{
								eStr = "--";
							}
							
							break;
						}

						case 88/*FIELD_2ND_HOUR*/:
						{
							eStr = formatHourForDisplayString(hour2nd, deviceSettings.is24Hour, propAddLeadingZero);	// hours
							break;
						}

						case 89/*FIELD_CALORIES*/:
						{
							eStr = "" + getNullCheckZero(activityMonitorInfo.calories);
							break;
						}

						case 90/*FIELD_ACTIVE_CALORIES*/:
						{
							var nonActiveCalories = propNonActiveCalories;
							if (nonActiveCalories<=0)
							{
								var userProfile = UserProfile.getProfile();
								var BMR = (10.0/1000.0)*userProfile.weight + 6.25*userProfile.height - 5.0*(dateInfoMedium.year-userProfile.birthYear) + ((userProfile.gender==1/*GENDER_MALE*/)?5:(-161));
								nonActiveCalories = (BMR*1.2).toNumber();
							}
							var calories = getNullCheckZero(activityMonitorInfo.calories) - (nonActiveCalories * timeNowInMinutesToday) / (24*60); 
							eStr = "" + ((calories<0) ? "--" : calories);
							break;
						}

						case 91/*FIELD_INTENSITY*/:
						{
							eStr = "" + activityMonitorActiveMinutesWeekTotal;
							break;
						}

						case 92/*FIELD_INTENSITY_GOAL*/:
						{
							eStr = "" + activityMonitorActiveMinutesWeekGoal;
							break;
						}

						case 93/*FIELD_SMART_GOAL*/:
						{
							eStr = "" + activeMinutesWeekSmartGoal;
							break;
						}

						case 94/*FIELD_DISTANCE*/:
						{
							// convert cm to miles or km
							var d = getNullCheckZero(activityMonitorInfo.distance) / ((deviceSettings.distanceUnits==System.UNIT_STATUTE) ? 160934.4 : 100000.0);
							eStr = d.format("%.1f");
							break;
						}

						case 95/*FIELD_DISTANCE_UNITS*/:
						{
							eStr = ((deviceSettings.distanceUnits==System.UNIT_STATUTE) ? "mi" : "km");
							makeUpperCase = !isDynamicResourceSystemFont(resourceIndex);
							break;
						}

						case 96/*FIELD_PRESSURE*/:
						{
							if (hasPressureHistory)
							{
								var pressureSample = SensorHistory.getPressureHistory({:period => 1}).next();
								if (pressureSample!=null && pressureSample.data!=null)
								{ 
									eStr = (pressureSample.data / 100.0).format("%.1f");	// convert Pa to mbar
								}
								else
								{
									eStr = "---";
								}
							}
							break;
						}

						case 97/*FIELD_PRESSURE_UNITS*/:
						{
							eStr = "mb"; 	// mbar
							makeUpperCase = !isDynamicResourceSystemFont(resourceIndex);
							break;
						}

						case 98/*FIELD_ALTITUDE*/:
						{
							// convert m to feet or m
							eStr = ((deviceSettings.distanceUnits==System.UNIT_STATUTE) ? (positionAltitude*3.2808399) : positionAltitude).format("%d");
							break;
						}

						case 99/*FIELD_ALTITUDE_UNITS*/:
						{
							eStr = ((deviceSettings.distanceUnits==System.UNIT_STATUTE) ? "ft" : "m");
							makeUpperCase = !isDynamicResourceSystemFont(resourceIndex);
							break;
						}
					}
					
					if (eStr != null)
					{
						if (makeUpperCase)
						{
							eStr = eStr.toUpper();
						}

						var sLen = gfxCharArrayLen;
						var eLen;
						
						var dynamicResource;
						if (useUnsupportedFont)
						{
							gfxData[index+3] |= 0x40000000;		// unsupported flag
							dynamicResource = Graphics.FONT_SYSTEM_SMALL;
						}
						else
						{
							gfxData[index+3] &= ~0x40000000;		// unsupported flag
							dynamicResource = getDynamicResource(resourceIndex);
						}

						if (dynamicResource==null)
						{
							gfxData[index+4] = sLen;
							gfxData[index+5] = sLen;
							gfxData[index+6] = 0;
							break;
						}
	
						if (checkDiacritics)
						{
							eLen = addStringToCharArrayWithDiacritics(eStr, gfxCharArray, sLen, 256);
							gfxCharArrayLen = eLen + (eLen-sLen);
							eStr = StringUtil.charArrayToString(gfxCharArray.slice(sLen, eLen));	// string without diacritics

							gfxData[index+3] |= 0x80000000;		// diacritics flag
						}
						else
						{
							eLen = addStringToCharArray(eStr, gfxCharArray, sLen, 256);
							gfxCharArrayLen = eLen;

							gfxData[index+3] &= ~0x80000000;		// diacritics flag
						}
	
						gfxData[index+4] = sLen;	// string start
						gfxData[index+5] = eLen;	// string end
						gfxData[index+6] = dc.getTextWidthInPixels(eStr, dynamicResource);
						gfxData[indexCurField+4] += gfxData[index+6];	// total width					
					}
					
					break;
				}
				
				case 6:		// icon
				{
					if (!(fieldVisible && isVisible))
					{
						break;
					}

					gfxData[index+4] = 0;	// char
					gfxData[index+5] = 0;	// width

					var eDisplay = gfxData[index+1];

				    if (eDisplay>=0/*FIELD_SHAPE_CIRCLE*/ && eDisplay<=32/*FIELD_SHAPE_MOUNTAIN*/)
				    {
						//var iconsString = "ABCDEFGHIJKLMNOPQRSTUVWX";
						//eStr = iconsString.substring(e-FIELD_SHAPE_CIRCLE, e-FIELD_SHAPE_CIRCLE+1);
						//var charArray = [(e - FIELD_SHAPE_CIRCLE + ICONS_FIRST_CHAR_ID).toChar()];
						//eStr = StringUtil.charArrayToString(charArray);
						//var charArray = [(e - FIELD_SHAPE_CIRCLE + ICONS_FIRST_CHAR_ID).toChar()];
						var c = (eDisplay + 65/*ICONS_FIRST_CHAR_ID*/).toChar();

						var resourceIndex = ((gfxData[index+3] >> 16) & 0xFF);
						var dynamicResource = getDynamicResource(resourceIndex);
						if (dynamicResource==null)
						{
							break;
						}

						gfxData[index+4] = c;	// char
						gfxData[index+5] = dc.getTextWidthInPixels(c.toString(), dynamicResource);
						gfxData[indexCurField+4] += gfxData[index+5];	// total width					
				    }

					break;
				}
				
				case 7:		// movebar
				{
					if (!(fieldVisible && isVisible))
					{
						break;
					}

					gfxData[index+9] = activityMonitorMoveBarLevel;	// level
					gfxData[index+10] = 0;	// width

					var resourceIndex = ((gfxData[index+2] >> 16) & 0xFF);
					var dynamicResource = getDynamicResource(resourceIndex);
					if (dynamicResource==null)
					{
						break;
					}

					// moveBarLevel 0 = not triggered
					// moveBarLevel has range 1 to 5
					// moveBarNum goes from 1 to 5
					for (var i=0; i<5; i++)
					{
						var barIsOn = (i < gfxData[index+9]);
						var s = (barIsOn ? "1" : "0");
						var w = dc.getTextWidthInPixels(s, dynamicResource);

						gfxData[index+10] += w + ((i<4) ? -5 : 0);
					}
					
					gfxData[indexCurField+4] += gfxData[index+10];	// total width					

					break;
				}
				
				case 8:		// chart
				{
					if (!(fieldVisible && isVisible))
					{
						break;
					}

					calculateHeartRate(minute, second);
					heartChartVisible = true;	// we know it is visible now

					var axesSide = true;
					var axesBottom = false;

					gfxData[index+4] = (axesSide ? 55 : 51);	// width
					gfxData[indexCurField+4] += gfxData[index+4];	// total width					

					break;
				}
				
				case 9:		// rectangle
				{
					if (!isVisible)
					{
						break;
					}

					break;
				}
				
				case 10:	// ring
				{
					if (!isVisible)
					{
						break;
					}

					var eDisplay = (gfxData[index+1] & 0xFF);
					var eDirAnti = ((gfxData[index+1] & 0x100) != 0);	// false==clockwise

					var drawStart = gfxData[index+3];	// 0-59
					var drawEnd = gfxData[index+4];		// 0-59
					
					var drawRange;
					if (eDirAnti)	// anticlockwise
					{
						drawRange = (drawStart - drawEnd + 60)%60 + 1;	// 1-60
					}
					else
					{
						drawRange = (drawEnd - drawStart + 60)%60 + 1;	// 1-60
					}
								
					// calculate fill amounts from 0 to drawRange
					var noFill = false;
					var fillStart = 0;		// first segment of outer ring to draw as filled (0 to 59)
					var fillEnd = drawRange-1;		// last segment of outer ring to draw as filled (0 to 59)

					switch (eDisplay)
					{
						case 1:		// steps
						case 9:		// intensity
						case 10:	// smart intensity
						{
							var val = activityMonitorSteps;
							var goal = activityMonitorStepGoal;
							if (eDisplay==9)
							{
								val = activityMonitorActiveMinutesWeekTotal;
								goal = activityMonitorActiveMinutesWeekGoal;
							}
							else if (eDisplay==10)
							{
								val = activityMonitorActiveMinutesWeekTotal;
								goal = activeMinutesWeekSmartGoal;
							}
											
							fillEnd = ((goal>0) ? ((drawRange * val) / goal - 1) : -1);
							if (fillEnd>=drawRange)
							{
								if (drawRange<60)
								{
									fillEnd = drawRange;
								}
								else
								{
									fillEnd++;	// add that 1 back on again so multiples of goal correctly align at start 
									
									// once past val goal then use a different style - draw just two unfilled blocks moving around
									//var multiple = val / goal;
									fillStart = (fillEnd + (val/goal))%60;
									fillEnd = (fillEnd + 59)%60;	// same as -1
								}
							}
							
							break;
						}

						case 2:		// minutes
						{
				    		fillEnd = (minute * drawRange)/60 - 1;
							break;
						}
						
						case 3:		// hours
						case 5:		// 2nd time zone hours
						{
							var useHour = ((eDisplay==3) ? hour : hour2nd);  
					        if (deviceSettings.is24Hour)
					        {
				        		//backgroundOuterFillEnd = ((hour*60 + minute) * 120) / (24 * 60);
				        		fillEnd = ((useHour*60 + minute) * drawRange) / (24*60) - 1;
					        }
					        else        	// 12 hours
					        {
				        		fillEnd = (((useHour%12)*60 + minute) * drawRange) / (12*60) - 1;
					        }
							break;
				   		}
				   		
				   		case 4:		// battery percentage
				   		{
							fillEnd = (systemStats.battery * drawRange).toNumber() / 100 - 1;
							break;
				   		}
				   		
				   		case 6:		// sunrise & sunset now top
				   		case 7:		// sunrise & sunset midnight top
				   		case 8:		// sunrise & sunset noon top
				   		{
							calculateSun(dateInfoShort);

							var timeOffsetInMinutes = 0;	// midnight top
							if (eDisplay==6)				// now top
							{
								timeOffsetInMinutes = timeNowInMinutesToday;
							}
							else if (eDisplay==8)			// noon top
							{
								timeOffsetInMinutes = 12*60;
							}

							fillStart = getSunOuterFill(sunTimes[0], timeOffsetInMinutes, 0, drawRange);
							fillEnd = getSunOuterFill(sunTimes[1], timeOffsetInMinutes, -1, drawRange);

							break;
				   		}
				   		
				   		case 11:	// heart rate
				   		{
							calculateHeartRate(minute, second);
							fillEnd = getMinMax((heartDisplayLatest * drawRange) / heartMaxZone5, 0, drawRange) - 1;
							break;
				   		}
				   		
				   		case 0:		// plain color
				   		default:
						{
							break;
						}
					}
					
					if (fillEnd < 0)
					{
						noFill = true;
						fillEnd = 0;
					}

					// apply fill offsets from start point
					if (eDirAnti)
					{
						fillStart = (drawStart - fillStart + 60) % 60;
						fillEnd = (drawStart - fillEnd + 60) % 60;
						
						var temp = fillStart;
						fillStart = fillEnd;
						fillEnd = temp;
					}
					else
					{
						fillStart = (drawStart + fillStart) % 60;
						fillEnd = (drawStart + fillEnd) % 60;
					}

					gfxData[index+7] = (fillStart & 0xFF) | ((fillEnd & 0xFF) << 8) | (noFill ? 0x10000 : 0);	// start fill, end fill and no fill flag

					break;
				}
				
				case 11:	// seconds
				{
			    	propSecondIndicatorOn = isVisible;
			    	propSecondRefreshStyle = ((gfxData[index+1] >> 8) & 0xFF);
					propSecondResourceIndex = ((gfxData[index+1] >> 16) & 0xFF);
			    	propSecondMoveInABit = ((gfxData[index+1] & 0x80000000) != 0);		// set depending on what the font is
					break;
				}
			}
			
			index += gfxSize(id);
		}
	}
	
	function gfxDrawBackground(dc, dcX, dcY, toBuffer)
	{
		var graphics = Graphics;

		var dcWidth = dc.getWidth();
		var dcHeight = dc.getHeight();

		var fieldDraw = false;
		var fieldXStart = 120;
		var fieldYStart = 120;

		var fieldX = 120;

		for (var index=0; index<gfxNum; )
		{
			var id = (gfxData[index] & 0xFF);
			var isVisible = ((gfxData[index] & 0x10000) != 0);
			
			switch(id)
			{
				case 0:		// header
				{
					break;
				}
				
				case 1:		// field
				{
        			//System.println("gfxDraw field");

					if (!isVisible)
					{
						fieldDraw = false;
						break;
					}

					var totalWidth = gfxData[index+4];

					fieldXStart = gfxData[index+1] - dcX + gfxData[index+5];	// add x adjustment
					fieldYStart = 240 - gfxData[index+2] - dcY;
			
					if (gfxData[index+3]==0)	// centre justification
					{
						fieldXStart -= totalWidth/2;
					}
					else if (gfxData[index+3]==2)	// right justification
					{
						fieldXStart -= totalWidth;
					}
					//else if (gfxData[index+3]==1)	// left justification
					//{
					//	// ok as is
					//}
			
					fieldDraw = ((fieldXStart<=dcWidth && (fieldXStart+totalWidth)>=0 && (fieldYStart-32)<=dcHeight && (fieldYStart-32+64)>=0));
					
					// should check height of data in field (large or small font etc)
					//Old field check: if (dateX<=dcWidth && (dateX+backgroundFieldTotalWidth[f])>=0 && (dateYOffset-23)<=dcHeight && (dateYOffset-23+38)>=0)
			
					fieldX = fieldXStart;

					break;
				}

				case 2:		// hour large
				case 3:		// minute large
				case 4:		// colon large
				{
        			//System.println("gfxDraw large");

					if (!(fieldDraw && isVisible))
					{
						break;
					}

					var resourceIndex = ((gfxData[index+2] >> 16) & 0xFF);
					var dynamicResource = getDynamicResource(resourceIndex);
					if (dynamicResource==null)
					{
						break;
					}

					var timeY = fieldYStart - graphics.getFontAscent(dynamicResource) + 30;
					
        			//System.println("ascent=" + graphics.getFontAscent(dynamicResource));
					
					if (gfxData[index+4]>0)	// width 1
					{
						if (fieldX<=dcWidth && (fieldX+gfxData[index+4])>=0)		// check digit x overlaps buffer
						{
							// align bottom of text
				       		dc.setColor(getColor64(gfxData[index+1]-1), -1/*COLOR_TRANSPARENT*/);
			        		dc.drawText(fieldX, timeY, dynamicResource, gfxData[index+3].toString(), 2/*TEXT_JUSTIFY_LEFT*/);
						}
													
		        		fieldX += gfxData[index+4];
		        	}

					if (fieldX<=dcWidth && (fieldX+gfxData[index+6])>=0)		// check digit x overlaps buffer
					{
			       		dc.setColor(getColor64(gfxData[index+1]-1), -1/*COLOR_TRANSPARENT*/);
		        		dc.drawText(fieldX, timeY, dynamicResource, gfxData[index+5].toString(), 2/*TEXT_JUSTIFY_LEFT*/);
					}

		        	fieldX += gfxData[index+6];

					break;
				}
				
				case 5: 	// string
				{
					if (!(fieldDraw && isVisible))
					{
						break;
					}

					var sLen = gfxData[index+4];
					var eLen = gfxData[index+5];
					if (eLen > sLen)
					{
						if (fieldX<=dcWidth && (fieldX+gfxData[index+6])>=0)	// check element x overlaps buffer
						{ 
							var dynamicResource;							
							if ((gfxData[index+3]&0x40000000)!=0)		// unsupported flag
							{
								dynamicResource = graphics.FONT_SYSTEM_SMALL;
							}
							else
							{
								var resourceIndex = ((gfxData[index+3] >> 16) & 0xFF);
								dynamicResource = getDynamicResource(resourceIndex);
							}
							
							if (dynamicResource==null)
							{
								break;
							}

							var dateY = fieldYStart - graphics.getFontAscent(dynamicResource) + 6;		// align bottom of text with bottom of icons
						
					        dc.setColor(getColor64(gfxData[index+2]-1), -1/*COLOR_TRANSPARENT*/);

							var s = StringUtil.charArrayToString(gfxCharArray.slice(sLen, eLen));
			        		dc.drawText(fieldX, dateY, dynamicResource, s, 2/*TEXT_JUSTIFY_LEFT*/);

							if ((gfxData[index+3]&0x80000000)!=0)		// diacritics flag
							{
								var num = eLen - sLen;
								for (var i=0; i<num; i++)
								{
									var c = gfxCharArray[eLen+i];
									if (c!=0)
									{
										var w = ((i>0) ? dc.getTextWidthInPixels(s.substring(0, i), dynamicResource) : 0); 
										dc.drawText(fieldX + w, dateY, dynamicResource, c.toString(), 2/*TEXT_JUSTIFY_LEFT*/);
									}
								}
							}	
						}
								
			        	fieldX += gfxData[index+6];
					}

					break;
				}
				
				case 6:		// icon
				{
					if (!(fieldDraw && isVisible))
					{
						break;
					}

					var c = gfxData[index+4];
					if (c > 0)
					{
						if (fieldX<=dcWidth && (fieldX+gfxData[index+5])>=0)	// check element x overlaps buffer
						{ 
							var resourceIndex = ((gfxData[index+3] >> 16) & 0xFF);
							var dynamicResource = getDynamicResource(resourceIndex);
							if (dynamicResource==null)
							{
								break;
							}

							var dateY = fieldYStart - graphics.getFontAscent(dynamicResource) + 6;		// align bottom of text with bottom of icons
						
					        dc.setColor(getColor64(gfxData[index+2]-1), -1/*COLOR_TRANSPARENT*/);
			        		dc.drawText(fieldX, dateY, dynamicResource, c.toString(), 2/*TEXT_JUSTIFY_LEFT*/);
						}

			        	fieldX += gfxData[index+5];
					}

					break;
				}
				
				case 7:		// movebar
				{
					if (!(fieldDraw && isVisible))
					{
						break;
					}

					var resourceIndex = ((gfxData[index+2] >> 16) & 0xFF);
					var dynamicResource = getDynamicResource(resourceIndex);
					if (dynamicResource==null)
					{
						break;
					}

					var dateX = fieldX;
					var dateY = fieldYStart - graphics.getFontAscent(dynamicResource) + 6;		// align bottom of text with bottom of icons

					// moveBarLevel 0 = not triggered
					// moveBarLevel has range 1 to 5
					// moveBarNum goes from 1 to 5
					for (var i=0; i<5; i++)
					{
						var barIsOn = (i < gfxData[index+9]);
						var s = (barIsOn ? "1" : "0");
						var w = dc.getTextWidthInPixels(s, dynamicResource);

						if (dateX<=dcWidth && (dateX+w)>=0)		// check element x overlaps buffer
						{ 
							var col = getColor64((barIsOn || gfxData[index+8]==COLOR_NOTSET) ? (gfxData[index+3+i]-1) : (gfxData[index+8]-1));
							
					        dc.setColor(col, -1/*COLOR_TRANSPARENT*/);
			        		dc.drawText(dateX, dateY, dynamicResource, s, 2/*TEXT_JUSTIFY_LEFT*/);
						}
						
						dateX += w + ((i<4) ? -5 : 0);
					}

		        	fieldX += gfxData[index+10];

					break;
				}
				
				case 8:		// chart
				{
					if (!(fieldDraw && isVisible))
					{
						break;
					}

					if (fieldX<=dcWidth && (fieldX+gfxData[index+4])>=0)	// check element x overlaps buffer
					{
						var axesSide = true;
						var axesBottom = false;
	
						drawHeartChart(dc, fieldX, fieldYStart+6, getColor64(gfxData[index+2]-1), getColor64(gfxData[index+3]-1), axesSide, axesBottom);		// draw heart rate chart
					}

		        	fieldX += gfxData[index+4];

					break;
				}
				
				case 9:		// rectangle
				{
					if (!isVisible)
					{
						break;
					}

					var w = gfxData[index+4];
					var h = gfxData[index+5];
					var x = gfxData[index+2] - dcX;
					var y = 240 - gfxData[index+3] - dcY - h;

					if (x<=dcWidth && (x+w)>=0 && y<=dcHeight && (y+h)>=0)
					{
				        dc.setColor(getColor64(gfxData[index+1]-1), -1/*COLOR_TRANSPARENT*/);
						dc.fillRectangle(x, y, w, h);
					}

					break;
				}
				
				case 10:	// ring
				{
					if (!isVisible)
					{
						break;
					}

					// positions of the outerBig segments (from fnt file)
					// y are all adjusted -1 as usual
					//var outerBigXY = [118, -2-1, 200, 34-1, 200, 118-1, 118, 200-1, 34, 200-1, -2, 118-1, -2, 34-1, 34, -2-1];
					//var outerBigXY = [118, -3, 200, 33, 200, 117, 118, 199, 34, 199, -2, 117, -2, 33, 34, -3];
		
					var resourceIndex = ((gfxData[index+2] >> 16) & 0xFF);
					var dynamicResource = getDynamicResource(resourceIndex);
					if (dynamicResource==null)
					{
						break;
					}

					var jStart;
					var jEnd;
			
					if (!toBuffer)		// main display
					{
						jStart = 0;
						jEnd = 59;		// all segments
					}
					else				// offscreen buffer
					{
						// these arrays contain outer ring segment numbers (0-119) for the offscreen buffer positions
											  		// t2   tr   r1   r2   br   b1   b2   bl   l1   l2   tl   t1
						//var outerOffscreenStart = 	[  -2,   7,  19,  28,  37,  49,  58,  67,  79,  88,  97, 109 ];
						//var outerOffscreenEnd = 	[   9,  22,  30,  39,  52,  59,  69,  82,  89,  99, 112, 120 ];
					
		    			jStart = outerValues[bufferIndex] - 10;
		    			jEnd = outerValues[bufferIndex + 12];
					}
			
					//jStart = 0;	// test draw all
					//jEnd = 119;
		
					// intersect the jStart to jEnd range with the drawing range
					var drawStart = gfxData[index+3];	// 0-59
					var drawEnd = gfxData[index+4];		// 0-59

					var eDirAnti = ((gfxData[index+1] & 0x100) != 0);	// false==clockwise
					if (eDirAnti)	// swap start & end for clockwise drawing
					{
						var temp = drawStart;
						drawStart = drawEnd;
						drawEnd = temp;					
					}
					
					var drawRange = (drawEnd - drawStart + 60)%60;	// 0-59
					var jRange = jEnd - jStart;
					
//System.println("drawStart=" + drawStart + " drawEnd=" + drawEnd);

					var loopStart;
					var loopEnd;
					var testStart;
					var testRange;

					// want to iterate through whichever is the smaller range - jRange or drawRange
					if (drawRange < jRange)
					{
						loopStart = drawStart;
						loopEnd = drawStart + drawRange; 
						testStart = jStart;
						testRange = jRange; 
					}
					else
					{
						loopStart = jStart;
						loopEnd = jStart + jRange; 
						testStart = drawStart;
						testRange = drawRange; 
					}
					
//System.println("jStart=" + jStart + " jEnd=" + jEnd);

					var colFilled = getColor64(gfxData[index+5]-1);
					var colUnfilled = getColor64(gfxData[index+6]-1);
					var fillStart = (gfxData[index+7]&0xFF);
					var fillEnd = ((gfxData[index+7]>>8)&0xFF);
					var noFill = ((gfxData[index+7]&0x10000)!=0);

					if (fillEnd<fillStart)	// swap them around so our test for filled/unfilled later is cheaper
					{
						var m = colFilled;
						colFilled = colUnfilled;
						colUnfilled = m;
						
						var n = fillStart; 
						fillStart = (fillEnd+1)%60;	// + 1
						fillEnd = (n+59)%60;		// - 1
					}

					if (noFill)
					{
						colFilled = colUnfilled;
					}
		
					var xOffset = -dcX - 8/*OUTER_SIZE_HALF*/;
					var yOffset = -dcY - 8/*OUTER_SIZE_HALF*/;
					var curCol = COLOR_NOTSET;
			
					// draw the correct segments
					for (var j=loopStart; j<=loopEnd; j++)
					{
						var index = (j+60)%60;	// handle segments <0 and >=60 and convert them into 0 to 59
						
						// don't draw segments outside the range
						var testOffset = (index-testStart+60)%60;
						if (testOffset>testRange)
						{
							continue;
						}
						
						var indexCol = ((index>=fillStart && index<=fillEnd) ? colFilled : colUnfilled); 
		
						// draw the segment (if a color is set)
						if (indexCol != COLOR_NOTSET)
						{
							if (curCol!=indexCol)
							{
								curCol = indexCol;
			       				dc.setColor(curCol, -1/*COLOR_TRANSPARENT*/);
			       			}
		
							//var s = characterString.substring(index, index+1);
							//var s = StringUtil.charArrayToString([(index + OUTER_FIRST_CHAR_ID).toChar()]);
							//var s = (index + 12/*OUTER_FIRST_CHAR_ID*/).toChar().toString();
							var index2 = index*2;
				        	dc.drawText(xOffset + outerXY[index2], yOffset + outerXY[index2+1], dynamicResource, (index + 12/*OUTER_FIRST_CHAR_ID*/).toChar().toString(), 2/*TEXT_JUSTIFY_LEFT*/);
				        }
					}

					break;
				}
				
				case 11:	// seconds
				{
					break;
				}
			}
			
			index += gfxSize(id);
		}
	}
}

(:m2app)
class myEditorView extends myView
{
	var timer;

    function initialize()
    {
		myView.initialize();
    }

	function onLayout(dc)
	{
		myView.onLayout(dc);
		
		timer = new Timer.Timer();
		timer.start(method(:timerCallback), 1000, true);

		myMenuItem.editorView = Application.getApp().mainView.sharedView;
		menuItem = new myMenuItemFieldSelect();
	}

	function timerCallback()
	{
    	WatchUi.requestUpdate();
	}

	var reloadDynamicResources = false;
	
	function checkReloadDynamicResources()
	{
		var temp = reloadDynamicResources;
		reloadDynamicResources = false; 
		return temp;
	}

	/*
	select field
		edit elements
			select element
				edit
					data
					visibility
					color
						next
						previous
						tap
					font
				delete element
			add element
		visibility
		position
			x adjust
			y adjust
			tap
		alignment
			left edge
			right edge
			centre
		delete field
		move field up
		move field down
		
		rectangle
			visibility
			color
			position
				x
				y
				tap
			width
			height
			
		ring
			visibility
			type
			font
			start
			end
			color filled
			color unfilled
				
		seconds
			visibility
			font
			refresh style
			color
			color5
			color10
			color15
			color0
		
	add field
		line blank
		freeform blank
		rectangle
		ring
		seconds
		
	quick add
		time
		time with colon
		date
		steps as text
		steps as ring
		heart rate as text
		seconds indicator
		digital seconds

	save profile
	load profile
	reset (delete all)
	*/
	
	var menuItem;
	
	var menuCurGfx = 0;

	function nextGfx(index)
	{
		var id = (gfxData[index] & 0xFF);
		var nextIndex = index + gfxSize(id);
		return ((nextIndex<gfxNum) ? nextIndex : -1);
	}

	function prevGfx(index)
	{
		var prevIndex = -1;
		for (var temp=0; temp<gfxNum; )
		{
			if (temp==index)
			{
				break;
			}
			
			prevIndex = temp;

			var id = (gfxData[temp] & 0xFF);
			temp += gfxSize(id);
		}
		
		return ((prevIndex<gfxNum) ? prevIndex : -1);
	}

	function gfxIsField(index)
	{
		var id = (gfxData[index] & 0xFF);
		switch(id)
		{
			case 0:		// header
			case 1:		// field
			case 9:		// rectangle
			case 10:	// ring
			case 11:	// seconds
			{
				return true;
			}

			case 2:		// hour large
			case 3:		// minute large
			case 4:		// colon large
			case 5:		// string
			case 6:		// icon
			case 7:		// movebar
			case 8:		// chart
			{
				break;
			}
		}
		return false;
	}

	function nextGfxField(index)
	{
		var temp;
		for (temp=nextGfx(index); temp>=0; temp=nextGfx(temp))
		{
			if (gfxIsField(temp))
			{
				return temp;
			}
		}
		return -1;
	}

	function prevGfxField(index)
	{
		var prevIndex = -1;
		for (var temp=0; temp>=0; )
		{
			if (temp==index)
			{
				break;
			}
			
			prevIndex = temp;

			temp = nextGfxField(temp);
		}		
		return prevIndex;
	}

    function onMenu()	// hold left middle button
    {   
    	WatchUi.requestUpdate();

        return true;
    }

    function onNextPage()	// tap left bottom
    {
    	var newMenuItem = menuItem.onNext();
    	if (newMenuItem!=null)
    	{
    		menuItem = newMenuItem;
    	}

    	WatchUi.requestUpdate();
    
        return true;
    }

    function onPreviousPage()	// tap left middle
    {
    	var newMenuItem = menuItem.onPrevious();
    	if (newMenuItem!=null)
    	{
    		menuItem = newMenuItem;
    	}
    
    	WatchUi.requestUpdate();
    
        return true;
    }

    function onSelect()		// tap right top
    {
    	var newMenuItem = menuItem.onSelect();
    	if (newMenuItem!=null)
    	{
    		menuItem = newMenuItem;
    	}

    	WatchUi.requestUpdate();
    
        return true;
    }

    function onBack()	// tap right bottom
    {
    	var newMenuItem = menuItem.onBack();
    	if (newMenuItem!=null)
    	{
    		menuItem = newMenuItem;

			if (menuItem.exitApp())
	    	{
	   			return false;	// return false here to exit the app
	    	}
    	}

    	WatchUi.requestUpdate();
    
        return true;
    }

    function onKey(keyEvent) 	// a physical button has been pressed and released. 
    {
		//keyEvent.getKey();
		//KEY_POWER = power key
		//KEY_LIGHT = light key
		//KEY_ZIN = zoom in key
		//KEY_ZOUT = zoom out key
		//KEY_ENTER = enter key
		//KEY_ESC = escape key
		//KEY_FIND = find key
		//KEY_MENU = menu key
		//KEY_DOWN = down key
		//KEY_DOWN_LEFT = down left key
		//KEY_DOWN_RIGHT = down right key
		//KEY_LEFT = left key
		//KEY_RIGHT = right key
		//KEY_UP = up key
		//KEY_UP_LEFT = up left key
		//KEY_UP_RIGHT = up right key

		//keyEvent.getType();
		//PRESS_TYPE_DOWN = key is pressed down
		//PRESS_TYPE_UP = key is released
		//PRESS_TYPE_ACTION = key's action is performed
    
    	return false;
    }
    
    function onKeyPressed(keyEvent) 	// a physical button has been pressed down. 
    {
    	return false;
    }
    
    function onKeyReleased(keyEvent) 	// a physical button has been released. 
    {
    	return false;
    }
        
    function onTap(clickEvent)		// a screen tap event has occurred. 
    {
    	//clickEvent.getCoordinates();
    	//clickEvent.getType();
    	//CLICK_TYPE_TAP = tap on the screen
		//CLICK_TYPE_HOLD = press and hold on the screen
		//CLICK_TYPE_RELEASE = release of a hold on the screen

    	return false;
    }

    function onHold(clickEvent)		// a touch screen hold event has occurred. 
    {
    	//clickEvent.getCoordinates();
    	//clickEvent.getType();
    	//CLICK_TYPE_TAP = tap on the screen
		//CLICK_TYPE_HOLD = press and hold on the screen
		//CLICK_TYPE_RELEASE = release of a hold on the screen

    	return false;
    }
    
    function onRelease(clickEvent) 		// a touch screen release event has occurred. 
    {
    	//clickEvent.getCoordinates();
    	//clickEvent.getType();
    	//CLICK_TYPE_TAP = tap on the screen
		//CLICK_TYPE_HOLD = press and hold on the screen
		//CLICK_TYPE_RELEASE = release of a hold on the screen

    	return false;
    }
    
    function onSwipe(swipeEvent) 	// a touch screen swipe event has occurred. 
    {
    	//swipeEvent.getDirection();
 		//SWIPE_UP = swipe in the upward direction
		//SWIPE_RIGHT = swipe towards the right
		//SWIPE_DOWN = swipe in the downward direction
		//SWIPE_LEFT = swipe towards the left
    	
    	return false;
    }    

    function onUpdate(dc)
    {
    	if (true)
    	{
			applicationProperties.setValue("PM", 0);

			var charArray = gfxToCharArray();
			var s = StringUtil.charArrayToString(charArray);
			if (s!=null)
			{
				applicationProperties.setValue("EP", s);
			}
		}

    	myView.onUpdate(dc);	// draw the normal watchface
    	
    	// then draw any menus on top
    	var eStr = menuItem.getString();

		if (eStr != null)
		{
	        dc.setColor(Graphics.COLOR_WHITE, -1/*COLOR_TRANSPARENT*/);
    		dc.drawText(50, 50, Graphics.FONT_SYSTEM_XTINY, eStr, 2/*TEXT_JUSTIFY_LEFT*/);
		}
    }

	function getGfxId(index)
	{
		return (gfxData[index] & 0xFF);
	}
	
	function getGfxName(index)
	{
		var eStr = null;
	
		var id = (gfxData[index] & 0xFF);
		switch(id)
		{
			case 0:		// header
			{
				eStr = "header";
				break;
			}

			case 1:		// field
			{
				eStr = "field";
				break;
			}

			case 2:		// hour large
			{
				eStr = "hour (large)";
				break;
			}

			case 3:		// minute large
			{
				eStr = "minute (large)";
				break;
			}

			case 4:		// colon large
			{
				eStr = "colon (large)";
				break;
			}

			case 5:		// string
			{
				var eDisplay = gfxData[index+1];
				
				switch(eDisplay)	// type of string
				{
					case 1/*FIELD_HOUR*/:			// hour
				    {
						eStr = "hour";
						break;
					}

					case 2/*FIELD_MINUTE*/:			// minute
				    {
						eStr = "minute";
						break;
					}

					case 3/*FIELD_DAY_NAME*/:		// day name
				    {
						eStr = "day (name)";
						break;
					}
					
					case 9/*FIELD_MONTH_NAME*/:		// month name
				    {
						eStr = "month (name)";
						break;
					}

					case 4/*FIELD_DAY_OF_WEEK*/:			// day number of week
				    {
						eStr = "day (number of week)";	// 1-7
						break;
					}

					case 5/*FIELD_DAY_OF_MONTH*/:			// day number of month
				    {
						eStr = "day (number of month)";
						break;
					}

					case 6/*FIELD_DAY_OF_MONTH_XX*/:			// day number of month XX
				    {
						eStr = "day (of month XX)";
						break;
					}

					case 7/*FIELD_DAY_OF_YEAR*/:				// day number of year
				    {
						eStr = "day (number of year)";
						break;
					}

					case 8/*FIELD_DAY_OF_YEAR_XXX*/:			// day number of year XXX
				    {
						eStr = "day (of year XXX)";
						break;
					}

					case 10/*FIELD_MONTH_OF_YEAR*/:		// month number of year
				    {
						eStr = "month (number)";
						break;
					}

					case 11/*FIELD_MONTH_OF_YEAR_XX*/:			// month number of year XX
				    {
						eStr = "month (number XX)";
						break;
					}

					case 12/*FIELD_YEAR_XX*/:		// year XX
					{
						eStr = "year (XX)";
						break;
					}

					case 13/*FIELD_YEAR_XXXX*/:		// year XXXX
				    {
						eStr = "year (XXXX)";
						break;
					}

					case 14/*FIELD_WEEK_ISO_XX*/:			// week number of year XX
				    {
						eStr = "week (ISO XX)";
						break;
					}

					case 15/*FIELD_WEEK_ISO_WXX*/:		// week number of year WXX
				    {
						eStr = "week (ISO WXX)";
						break;
					}

					case 16/*FIELD_YEAR_ISO_WEEK_XXXX*/:
				    {
						eStr = "year (ISO week XXXX)";
						break;
					}

					case 17/*FIELD_WEEK_CALENDAR_XX*/:			// week number of year XX
				    {
						eStr = "week (calendar)";
						break;
					}

					case 18/*FIELD_YEAR_CALENDAR_WEEK_XXXX*/:
					{
						eStr = "year (calendar week XXXX)";
						break;
					}

					case 19/*FIELD_AM*/:
				    {
						eStr = "AM";
						break;
					}

					case 20/*FIELD_PM*/:
				    {
						eStr = "PM";
						break;
					}

				    case 21/*FIELD_SEPARATOR_SPACE*/:
				    case 22:
				    case 23:
				    case 24:
				    case 25:
				    case 26:
				    case 27:
				    case 28/*FIELD_SEPARATOR_PERCENT*/:
				    {
						var separatorString = " /\\:-.,%";
	        			eStr = separatorString.substring(eDisplay-21/*FIELD_SEPARATOR_SPACE*/, eDisplay-21/*FIELD_SEPARATOR_SPACE*/+1);
	        			break;
				    }

					case 31/*FIELD_STEPSCOUNT*/:
					{
						eStr = "steps count";
						break;
					}

					case 32/*FIELD_STEPSGOAL*/:
					{
						eStr = "steps goal";
						break;
					}

					case 33/*FIELD_FLOORSCOUNT*/:
					{
						eStr = "floors count";
						break;
					}

					case 34/*FIELD_FLOORSGOAL*/:
					{
						eStr = "floors goal";
						break;
					}

					case 35/*FIELD_NOTIFICATIONSCOUNT*/:
					{
						eStr = "notifications count";
						break;
					}
					
					case 36/*FIELD_BATTERYPERCENTAGE*/:
					{
						eStr = "battery percentage";
						break;
					}
					
					case 76/*FIELD_HEART_MIN*/:
					{
						eStr = "heart rate min";
						break;
					}

					case 77/*FIELD_HEART_MAX*/:
					{
						eStr = "heart rate max";
						break;
					}

					case 78/*FIELD_HEART_AVERAGE*/:
					{
						eStr = "heart rate average";
						break;
					}

					case 79/*FIELD_HEART_LATEST*/:
					{
						eStr = "heart rate";
						break;
					}

					case 82/*FIELD_SUNRISE_HOUR*/:
					{
						eStr = "sunrise hour";
						break;
					}

					case 83/*FIELD_SUNRISE_MINUTE*/:
					{
						eStr = "sunrise hour";
						break;
					}

					case 84/*FIELD_SUNSET_HOUR*/:
					{
						eStr = "sunset hour";
						break;
					}

					case 85/*FIELD_SUNSET_MINUTE*/:
					{
						eStr = "sunset minute";
						break;
					}

					case 86/*FIELD_SUNEVENT_HOUR*/:
					{
						eStr = "next sun event hour";
						break;
					}

					case 87/*FIELD_SUNEVENT_MINUTE*/:
					{
						eStr = "next sun event minute";
						break;
					}

					case 88/*FIELD_2ND_HOUR*/:
					{
						eStr = "2nd time zone hour";
						break;
					}

					case 89/*FIELD_CALORIES*/:
					{
						eStr = "calories";
						break;
					}

					case 90/*FIELD_ACTIVE_CALORIES*/:
					{
						eStr = "active calories";
						break;
					}

					case 91/*FIELD_INTENSITY*/:
					{
						eStr = "intensity minutes";
						break;
					}

					case 92/*FIELD_INTENSITY_GOAL*/:
					{
						eStr = "intensity goal";
						break;
					}

					case 93/*FIELD_SMART_GOAL*/:
					{
						eStr = "smart intensity goal";
						break;
					}

					case 94/*FIELD_DISTANCE*/:
					{
						eStr = "distance";
						break;
					}

					case 95/*FIELD_DISTANCE_UNITS*/:
					{
						eStr = "distance units (mi/km)";
						break;
					}

					case 96/*FIELD_PRESSURE*/:
					{
						eStr = "pressure";
						break;
					}

					case 97/*FIELD_PRESSURE_UNITS*/:
					{
						eStr = "pressure units (mb)";
						break;
					}

					case 98/*FIELD_ALTITUDE*/:
					{
						eStr = "altitude";
						break;
					}

					case 99/*FIELD_ALTITUDE_UNITS*/:
					{
						eStr = "altitude units (ft/m)";
						break;
					}
				}
				
				break;
			}
			
			case 6:		// icon
			{
				eStr = "icon";
				break;
			}
			
			case 7:		// movebar
			{
				eStr = "move bar";
				break;
			}
			
			case 8:		// chart
			{
				eStr = "heart rate chart";
				break;
			}
			
			case 9:		// rectangle
			{
				eStr = "rectangle";
				break;
			}
			
			case 10:	// ring
			{
				eStr = "ring";
				break;
			}
			
			case 11:	// seconds
			{
				eStr = "seconds indicator";
				break;
			}
		}
		
		return eStr;
	}

	function fieldVisibilityString()
	{
		switch (fieldGetVisibility())
		{
			case 0/*STATUS_ALWAYSON*/: return "always on";
		    case 1/*STATUS_DONOTDISTURB_ON*/: return "do not disturb on";
		    case 2/*STATUS_DONOTDISTURB_OFF*/: return "do not disturb off";
		    case 3/*STATUS_ALARM_ON*/: return "alarm on";
		    case 4/*STATUS_ALARM_OFF*/: return "alarm off";
		    case 5/*STATUS_NOTIFICATIONS_PENDING*/: return "notifications pending";
		    case 6/*STATUS_NOTIFICATIONS_NONE*/: return "no notifications";
		    case 7/*STATUS_PHONE_CONNECTED*/: return "phone connected";
		    case 8/*STATUS_PHONE_NOT*/: return "phone not connected";
		    case 9/*STATUS_LTE_CONNECTED*/: return "LTE connected";
		    case 10/*STATUS_LTE_NOT*/: return "LTE not connected";
		    case 11/*STATUS_BATTERY_HIGHORMEDIUM*/: return "battery high or medium";
		    case 12/*STATUS_BATTERY_HIGH*/: return "battery high";
		    case 13/*STATUS_BATTERY_MEDIUM*/: return "battery medium";
		    case 14/*STATUS_BATTERY_LOW*/: return "battery low";
		    case 15/*STATUS_MOVEBARALERT_TRIGGERED*/: return "move bar alert triggered";
		    case 16/*STATUS_MOVEBARALERT_NOT*/: return "move bar alert not triggered";
		    case 17/*STATUS_AM*/: return "AM";
		    case 18/*STATUS_PM*/: return "PM";
		    case 19/*STATUS_2ND_AM*/: return "2nd time zone AM";
		    case 20/*STATUS_2ND_PM*/: return "2nd time zone PM";
		    case 21/*STATUS_SUNEVENT_RISE*/: return "next sun event is rise";
		    case 22/*STATUS_SUNEVENT_SET*/: return "next sun event is set";
		    case 23/*STATUS_GLANCE_ON*/: return "gesture active";
		    case 24/*STATUS_GLANCE_OFF*/: return "gesture not active";
		}
		
    	return "unknown";
	}
	
	function fieldGetVisibility()
	{
		return ((gfxData[menuCurGfx] >> 8) & 0xFF);
	}

	function fieldSetVisibility(val)
	{
		gfxData[menuCurGfx] &= ~(0xFF << 8);
		gfxData[menuCurGfx] |= ((val & 0xFF) << 8);
	}

	function fieldPositionXEditing(val)
	{
		gfxData[menuCurGfx+1] = getMinMax(gfxData[menuCurGfx+1]+val, 0, 240);
	}

	function fieldPositionYEditing(val)
	{
		gfxData[menuCurGfx+2] = getMinMax(gfxData[menuCurGfx+2]+val, 0, 240);
	}

	function fieldPositionCentreX()
	{
		gfxData[menuCurGfx+1] = 120;
	}

	function fieldPositionCentreY()
	{
		gfxData[menuCurGfx+2] = 120;
	}

	function fieldSetAlignment(val)
	{
		gfxData[menuCurGfx+3] = val;
	}

	function fieldGetAlignment()
	{
		return gfxData[menuCurGfx+3];
	}

	function fieldSwap(prevField, nextField)
	{
		var diff = nextField - prevField;
		var tempArray = gfxData.slice(prevField, nextField);
		
		var endField = nextGfxField(nextField);
		if (endField<0)
		{
			endField = gfxNum;
		}

		for (var index=nextField; index<endField; index++)
		{
			gfxData[index-diff] = gfxData[index];
		}
		
		for (var index=0; index<diff; index++)
		{
			gfxData[endField-diff+index] = tempArray[index];
		}
		
		return endField-diff;	// new start index of new later field
	}

	function fieldEarlier()
	{
		var prevField = prevGfxField(menuCurGfx);
		if (prevField>0)	// 0==header
		{
			fieldSwap(prevField, menuCurGfx);

			menuCurGfx = prevField;			
		}
	}

	function fieldLater()
	{
		var nextField = nextGfxField(menuCurGfx);
		if (nextField>=0)
		{
			menuCurGfx = fieldSwap(menuCurGfx, nextField);
		}
	}

	function fieldDelete()
	{
		var nextField = nextGfxField(menuCurGfx);
		if (nextField>=0)
		{
			var diff = nextField - menuCurGfx;
			for (var index=nextField; index<gfxNum; index++)
			{
				gfxData[index-diff] = gfxData[index];
			}
			
			gfxNum -= diff;
		}
		else
		{
			var prevField = prevGfxField(menuCurGfx);
			
			menuCurGfx = prevField;
			gfxNum = menuCurGfx; 
		}
	}

	function rectangleGetVisibility()
	{
		return ((gfxData[menuCurGfx] >> 8) & 0xFF);
	}

	function rectangleSetVisibility(val)
	{
		gfxData[menuCurGfx] &= ~(0xFF << 8);
		gfxData[menuCurGfx] |= ((val & 0xFF) << 8);
	}

	function rectangleGetColor()
	{
		return gfxData[menuCurGfx+1];
	}

	function rectangleSetColor(val)
	{
		gfxData[menuCurGfx+1] = val;
	}

	function rectanglePositionXEditing(val)
	{
		gfxData[menuCurGfx+2] = getMinMax(gfxData[menuCurGfx+2]+val, 0, 240);
	}

	function rectanglePositionYEditing(val)
	{
		gfxData[menuCurGfx+3] = getMinMax(gfxData[menuCurGfx+3]+val, 0, 240);
	}

	function rectanglePositionCentreX()
	{
		gfxData[menuCurGfx+2] = 120 - gfxData[menuCurGfx+4]/2;
	}

	function rectanglePositionCentreY()
	{
		gfxData[menuCurGfx+3] = 120 - gfxData[menuCurGfx+5]/2;
	}

	function rectangleWidthEditing(val)
	{
		if ((val<0) && (gfxData[menuCurGfx+4]%2)==0)
		{
			gfxData[menuCurGfx+2] += 1;
		}
		gfxData[menuCurGfx+4] = getMinMax(gfxData[menuCurGfx+4]+val, 1, 240);
		if ((val>0) && (gfxData[menuCurGfx+4]%2)==0)
		{
			gfxData[menuCurGfx+2] -= 1;
		}
	}

	function rectangleHeightEditing(val)
	{
		if ((val<0) && (gfxData[menuCurGfx+5]%2)==0)
		{
			gfxData[menuCurGfx+3] += 1;
		}
		gfxData[menuCurGfx+5] = getMinMax(gfxData[menuCurGfx+5]+val, 1, 240);
		if ((val>0) && (gfxData[menuCurGfx+5]%2)==0)
		{
			gfxData[menuCurGfx+3] -= 1;
		}
	}

	function ringTypeString()
	{
		switch (gfxData[menuCurGfx+1] & 0xFF)
		{
	   		case 0: return "plain color";		// plain color
			case 1: return "steps";				// steps
			case 2:	return "minutes";			// minutes
			case 3:	return "hours";				// hours
	   		case 4: return "battery";			// battery percentage
			case 5: return "2nd time zone hours";	// 2nd time zone hours
	   		case 6: return "sun (now top)";			// sunrise & sunset now top
	   		case 7: return "sun (midnight top)";	// sunrise & sunset midnight top
	   		case 8: return "sun (noon top)";		// sunrise & sunset noon top
			case 9: return "intensity";			// intensity
			case 10: return "smart intensity";	// smart intensity
	   		case 11: return "heart rate";		// heart rate
		}
		
    	return "unknown";
	}
	
	function ringTypeEditing(val)
	{
		var eDisplay = ((gfxData[menuCurGfx+1] & 0xFF) + val + 11)%11;
		gfxData[menuCurGfx+1] &= ~0xFF; 
		gfxData[menuCurGfx+1] |= (eDisplay & 0xFF); 
	}
	
	function ringDirectionString()
	{
		return ((gfxData[menuCurGfx+1] & 0x100)!=0) ? "anticlockwise" : "clockwise"; 
	}
	
	function ringDirectionEditing()
	{
		gfxData[menuCurGfx+1] ^= 0x100;
		
		// swap start and end over too
		var temp = gfxData[menuCurGfx+3];
		gfxData[menuCurGfx+3] = gfxData[menuCurGfx+4];
		gfxData[menuCurGfx+4] = temp;
	}
	
	function ringFontEditing(val)
	{
		gfxData[menuCurGfx+2] &= ~0xFF;
		gfxData[menuCurGfx+2] |= (0 & 0xFF);
		reloadDynamicResources = true;
	}
	
	function ringStartEditing(val)
	{
		gfxData[menuCurGfx+3] = (gfxData[menuCurGfx+3] + val + 60)%60;
	}
	
	function ringEndEditing(val)
	{
		gfxData[menuCurGfx+4] = (gfxData[menuCurGfx+4] + val + 60)%60;
	}
	
	function ringGetColorFilled()
	{
		return gfxData[menuCurGfx+5];
	}
	
	function ringSetColorFilled(val)
	{
		gfxData[menuCurGfx+5] = val;
	}
	
	function ringGetColorUnfilled()
	{
		return gfxData[menuCurGfx+6];
	}
	
	function ringSetColorUnfilled(val)
	{
		gfxData[menuCurGfx+6] = val;
	}
}

(:m2app)
class myMenuItem extends Lang.Object
{
	static var editorView;
	
    function initialize()
    {
    	Object.initialize();
    }
    
    function exitApp()
    {
    	return false;
    }
    
    function getString()
    {
    	return "unknown";
    }
    
    function onNext()
    {
    	return null;
    }
    
    function onPrevious()
    {
    	return null;
    }
    
    function onSelect()
    {
    	return null;
    }
    
    function onBack()
    {
    	return null;
    }
}

(:m2app)
class myMenuItemExitApp extends myMenuItem
{
    function initialize()
    {   	
    	myMenuItem.initialize();
    }
    
    function exitApp()
    {
    	return true;
    }
}

(:m2app)
class myMenuItemFieldSelect extends myMenuItem
{
    function initialize()
    {   	
    	myMenuItem.initialize();
    }
    
    function getString()
    {
    	return editorView.getGfxName(editorView.menuCurGfx);
    }
    
    function onNext()
    {
		var nextIndex = editorView.nextGfxField(editorView.menuCurGfx);
		if (nextIndex>=0)
		{
			editorView.menuCurGfx = nextIndex;
		}
    	else
    	{
    		return new myMenuItemAddField();
    	}
    	return null;
    }
    
    function onPrevious()
    {
    	var prevIndex = editorView.prevGfxField(editorView.menuCurGfx);
    	if (prevIndex>=0)
    	{
    		editorView.menuCurGfx = prevIndex;
    	}
    	return null;
    }
    
    function onSelect()
    {
		switch (editorView.getGfxId(editorView.menuCurGfx))
		{
			case 0:		// header
			{
    			return new myMenuItemHeader();
			}

			case 1:		// field
			{
    			return new myMenuItemFieldEdit();
			}

			case 9:		// rectangle
			{
    			return new myMenuItemRectangle();
			}

			case 10:	// ring
			{
    			return new myMenuItemRing();
			}

			case 11:	// seconds
			{
    			return new myMenuItemSeconds();
			}

			case 2:		// hour large
			case 3:		// minute large
			case 4:		// colon large
			case 5:		// string
			case 6:		// icon
			case 7:		// movebar
			case 8:		// chart
			{
				break;
			}
		}
			
		return null;
    }
    
    function onBack()
    {
    	return new myMenuItemExitApp();
    }
}

(:m2app)
class myMenuItemAddField extends myMenuItem
{
    function initialize()
    {   	
    	myMenuItem.initialize();
    }
    
    function getString()
    {
    	return "add field";
    }
    
    function onNext()
    {
   		return new myMenuItemQuickAdd();
    }
    
    function onPrevious()
    {
   		return new myMenuItemFieldSelect();
    }
    
    function onSelect()
    {
    	return null;
    }
    
    function onBack()
    {
    	return new myMenuItemExitApp();
    }
}

(:m2app)
class myMenuItemQuickAdd extends myMenuItem
{
    function initialize()
    {   	
    	myMenuItem.initialize();
    }
    
    function getString()
    {
    	return "quick add";
    }
    
    function onNext()
    {
   		return new myMenuItemSaveProfile();
    }
    
    function onPrevious()
    {
   		return new myMenuItemAddField();
    }
    
    function onSelect()
    {
    	return null;
    }
    
    function onBack()
    {
    	return new myMenuItemExitApp();
    }
}

(:m2app)
class myMenuItemSaveProfile extends myMenuItem
{
    function initialize()
    {   	
    	myMenuItem.initialize();
    }
    
    function getString()
    {
    	return "save profile";
    }
    
    function onNext()
    {
   		return new myMenuItemLoadProfile();
    }
    
    function onPrevious()
    {
   		return new myMenuItemQuickAdd();
    }
    
    function onSelect()
    {
    	return null;
    }
    
    function onBack()
    {
    	return new myMenuItemExitApp();
    }
}

(:m2app)
class myMenuItemLoadProfile extends myMenuItem
{
    function initialize()
    {   	
    	myMenuItem.initialize();
    }
    
    function getString()
    {
    	return "load profile";
    }
    
    function onNext()
    {
   		return new myMenuItemReset();
    }
    
    function onPrevious()
    {
   		return new myMenuItemSaveProfile();
    }
    
    function onSelect()
    {
    	return null;
    }
    
    function onBack()
    {
    	return new myMenuItemExitApp();
    }
}

(:m2app)
class myMenuItemReset extends myMenuItem
{
    function initialize()
    {   	
    	myMenuItem.initialize();
    }
    
    function getString()
    {
    	return "reset (delete all)";
    }
    
    function onNext()
    {
    	return null;
    }
    
    function onPrevious()
    {
   		return new myMenuItemLoadProfile();
    }
    
    function onSelect()
    {
    	return null;
    }
    
    function onBack()
    {
    	return new myMenuItemExitApp();
    }
}

(:m2app)
class myMenuItemHeader extends myMenuItem
{
    function initialize()
    {   	
    	myMenuItem.initialize();
    }
    
    function getString()
    {
    	return "header data";
    }
    
    function onNext()
    {
   		return null;
    }
    
    function onPrevious()
    {
   		return null;
    }
    
    function onSelect()
    {
    	return null;
    }
    
    function onBack()
    {
   		return new myMenuItemFieldSelect();
    }
}

(:m2app)
class myMenuItemFieldEdit extends myMenuItem
{
	enum
	{
		f_elements,
		f_vis,
		f_position,
		f_align,
		f_earlier,
		f_later,
		f_delete,

		f_x,
		f_y,
		f_xCentre,
		f_yCentre,
		f_tap,

		f_visEdit,
		f_xEdit,
		f_yEdit,
		f_alignEdit,
	}

	var fState = f_elements;

    function initialize()
    {   	
    	myMenuItem.initialize();
    }
    
    function getString()
    {
    	switch (fState)
    	{
			case f_elements: return "edit elements";
			case f_vis: return "visibility";
			case f_position: return "position";
			case f_align: return "alignment";
			case f_earlier: return "move earlier";
			case f_later: return "move later";
			case f_delete: return "delete field";

			case f_x: return "horizontal";
			case f_y: return "vertical";
			case f_xCentre: return "centre horizontal";
			case f_yCentre: return "centre vertical";
			case f_tap: return "tap";

			case f_visEdit: return editorView.fieldVisibilityString();
			case f_xEdit: return "editing ...";
			case f_yEdit: return "editing ...";
			
			case f_alignEdit:
		    	switch (editorView.fieldGetAlignment())
		    	{
		    		case 0: return "centre"; 
		    		case 1: return "left edge";
		    		case 2: return "right edge";
		    	}
				break;
    	}
    	
    	return "unknown";
    }
    
    function onNext()
    {
    	switch (fState)
    	{
			case f_elements: fState = f_vis; break;
			case f_vis: fState = f_position; break;
			case f_position: fState = f_align; break;
			case f_align: fState = f_earlier; break;
			case f_earlier: fState = f_later; break;
			case f_later: fState = f_delete; break;
			case f_delete: break;

			case f_x: fState = f_y; break;
			case f_y: fState = f_xCentre; break;
			case f_xCentre: fState = f_yCentre; break;
			case f_yCentre: fState = f_tap; break;
			case f_tap: fState = f_x; break;

			case f_visEdit: editorView.fieldSetVisibility((editorView.fieldGetVisibility()+1)%25/*STATUS_NUM*/); break;
			case f_xEdit: editorView.fieldPositionXEditing(-1); break;
			case f_yEdit: editorView.fieldPositionYEditing(-1); break;
			case f_alignEdit: editorView.fieldSetAlignment((editorView.fieldGetAlignment()+1)%3); break;
    	}

   		return null;
    }
    
    function onPrevious()
    {
    	switch (fState)
    	{
			case f_elements: break;
			case f_vis: fState = f_elements; break;
			case f_position: fState = f_vis; break;
			case f_align: fState = f_position; break;
			case f_earlier: fState = f_align; break;
			case f_later: fState = f_earlier; break;
			case f_delete: fState = f_later; break;

			case f_x: fState = f_tap; break;
			case f_y: fState = f_x; break;
			case f_xCentre: fState = f_y; break;
			case f_yCentre: fState = f_xCentre; break;
			case f_tap: fState = f_yCentre; break;

			case f_visEdit: editorView.fieldSetVisibility((editorView.fieldGetVisibility()+25/*STATUS_NUM*/-1)%25/*STATUS_NUM*/); break;
			case f_xEdit: editorView.fieldPositionXEditing(1); break;
			case f_yEdit: editorView.fieldPositionYEditing(1); break;
			case f_alignEdit: editorView.fieldSetAlignment((editorView.fieldGetAlignment()+3-1)%3); break;
    	}

   		return null;
    }
    
    function onSelect()
    {
    	switch (fState)
    	{
			case f_elements: break;
			case f_vis: fState = f_visEdit; break;
			case f_position: fState = f_x; break;
			case f_align: fState = f_alignEdit; break;
			case f_earlier: editorView.fieldEarlier(); break;
			case f_later: editorView.fieldLater(); break;
			case f_delete: editorView.fieldDelete(); return new myMenuItemFieldSelect();

			case f_x: fState = f_xEdit; break;
			case f_y: fState = f_yEdit; break;
			case f_xCentre: editorView.fieldPositionCentreX(); break;
			case f_yCentre: editorView.fieldPositionCentreY(); break;
			case f_tap: break;

			case f_visEdit: break;
			case f_xEdit: break;
			case f_yEdit: break;
			case f_alignEdit: break;
    	}

    	return null;
    }
    
    function onBack()
    {
    	switch (fState)
    	{
			case f_elements:
			case f_vis:
			case f_position:
			case f_align:
			case f_earlier:
			case f_later:
			case f_delete:
				return new myMenuItemFieldSelect();

			case f_x:
			case f_y:
			case f_xCentre:
			case f_yCentre:
			case f_tap:
				fState = f_position;
				break;

			case f_visEdit: fState = f_vis; break;
			case f_xEdit: fState = f_x; break;
			case f_yEdit: fState = f_y; break;
			case f_alignEdit: fState = f_align; break;
    	}

   		return null;
    }
}

(:m2app)
class myMenuItemRectangle extends myMenuItem
{
	enum
	{
		r_vis,
		r_color,
		r_position,
		r_w,
		r_h,
		r_earlier,
		r_later,
		r_delete,

		r_x,
		r_y,
		r_xCentre,
		r_yCentre,
		r_tap,

		r_visEdit,
		r_colorEdit,
		r_xEdit,
		r_yEdit,
		r_wEdit,
		r_hEdit
	}

	var rState = r_vis;

    function initialize()
    {   	
    	myMenuItem.initialize();
    }
    
    function getString()
    {
    	switch (rState)
    	{
			case r_vis: return "visibility";
			case r_color: return "color";
			case r_position: return "position";
			case r_w: return "width";
			case r_h: return "height";
			case r_earlier: return "move earlier";
			case r_later: return "move later";
			case r_delete: return "delete rectangle";

			case r_x: return "horizontal";
			case r_y: return "vertical";
			case r_xCentre: return "centre horizontal";
			case r_yCentre: return "centre vertical";
			case r_tap: return "tap";

			case r_visEdit: return editorView.fieldVisibilityString();
			case r_colorEdit: return "editing ...";
			case r_xEdit: return "editing ...";
			case r_yEdit: return "editing ...";
			case r_wEdit: return "editing ...";
			case r_hEdit: return "editing ...";
    	}
    	
    	return "unknown";
    }
    
    function onNext()
    {
    	switch (rState)
    	{
			case r_vis: rState = r_color; break;
			case r_color: rState = r_position; break;
			case r_position: rState = r_w; break;
			case r_w: rState = r_h; break;
			case r_h: rState = r_earlier; break;
			case r_earlier: rState = r_later; break;
			case r_later: rState = r_delete; break;
			case r_delete: break;

			case r_x: rState = r_y; break;
			case r_y: rState = r_xCentre; break;
			case r_xCentre: rState = r_yCentre; break;
			case r_yCentre: rState = r_tap; break;
			case r_tap: rState = r_x; break;

			case r_visEdit: editorView.fieldSetVisibility((editorView.fieldGetVisibility()+1)%25/*STATUS_NUM*/); break;
			case r_colorEdit: editorView.rectangleSetColor((editorView.rectangleGetColor()+1)%64); break;
			case r_xEdit: editorView.rectanglePositionXEditing(-1); break;
			case r_yEdit: editorView.rectanglePositionYEditing(-1); break;
			case r_wEdit: editorView.rectangleWidthEditing(-1); break;
			case r_hEdit: editorView.rectangleHeightEditing(-1); break;
    	}
    	
    	return null;
    }
    
    function onPrevious()
    {
    	switch (rState)
    	{
			case r_vis: break;
			case r_color: rState = r_vis; break;
			case r_position: rState = r_color; break;
			case r_w: rState = r_position; break;
			case r_h: rState = r_w; break;
			case r_earlier: rState = r_h; break;
			case r_later: rState = r_earlier; break;
			case r_delete: rState = r_later; break;

			case r_x: rState = r_tap; break;
			case r_y: rState = r_x; break;
			case r_xCentre: rState = r_y; break;
			case r_yCentre: rState = r_xCentre; break;
			case r_tap: rState = r_yCentre; break;

			case r_visEdit: editorView.fieldSetVisibility((editorView.fieldGetVisibility()+25/*STATUS_NUM*/-1)%25/*STATUS_NUM*/); break;
			case r_colorEdit: editorView.rectangleSetColor((editorView.rectangleGetColor()+64-1)%64); break;
			case r_xEdit: editorView.rectanglePositionXEditing(1); break;
			case r_yEdit: editorView.rectanglePositionYEditing(1); break;
			case r_wEdit: editorView.rectangleWidthEditing(1); break;
			case r_hEdit: editorView.rectangleHeightEditing(1); break;
    	}
    	
    	return null;
    }
    
    function onSelect()
    {
    	switch (rState)
    	{
			case r_vis: rState = r_visEdit; break;
			case r_color: rState = r_colorEdit; break;
			case r_position: rState = r_x; break;
			case r_w: rState = r_wEdit; break;
			case r_h: rState = r_hEdit; break;
			case r_earlier: editorView.fieldEarlier(); break;
			case r_later: editorView.fieldLater(); break;
			case r_delete: editorView.fieldDelete(); return new myMenuItemFieldSelect();

			case r_x: rState = r_xEdit; break;
			case r_y: rState = r_yEdit; break;
			case r_xCentre: editorView.rectanglePositionCentreX(); break;
			case r_yCentre: editorView.rectanglePositionCentreY(); break;
			case r_tap: break;

			case r_visEdit: break;
			case r_colorEdit: break;
			case r_xEdit: break;
			case r_yEdit: break;
			case r_wEdit: break;
			case r_hEdit: break;
    	}
    	
    	return null;
    }
    
    function onBack()
    {
    	switch (rState)
    	{
			case r_vis:
			case r_color:
			case r_position:
			case r_w:
			case r_h:
			case r_earlier:
			case r_later:
			case r_delete:
				return new myMenuItemFieldSelect();
				
			case r_x:
			case r_y:
			case r_xCentre:
			case r_yCentre:
			case r_tap: 
				rState = r_position;
				break;

			case r_visEdit: rState = r_vis; break;
			case r_colorEdit: rState = r_color; break;
			case r_xEdit: rState = r_x; break;
			case r_yEdit: rState = r_y; break;
			case r_wEdit: rState = r_w; break;
			case r_hEdit: rState = r_h; break;
    	}
    	
    	return null;
    }
}

(:m2app)
class myMenuItemRing extends myMenuItem
{
	enum
	{
		r_vis,
		r_type,
		r_font,
		r_start,
		r_end,
		r_direction,
		r_colorFilled,
		r_colorUnfilled,
		r_earlier,
		r_later,
		r_delete,

		r_visEdit,
		r_typeEdit,
		r_fontEdit,
		r_startEdit,
		r_endEdit,
		r_directionEdit,
		r_colorFilledEdit,
		r_colorUnfilledEdit,
	}

	var rState = r_vis;

    function initialize()
    {   	
    	myMenuItem.initialize();
    }
    
    function getString()
    {
    	switch (rState)
    	{
			case r_vis: return "visibility";
			case r_type: return "data";
			case r_font: return "style";
			case r_start: return "start";
			case r_end: return "end";
			case r_direction: return "direction";
			case r_colorFilled: return "color filled";
			case r_colorUnfilled: return "color unfilled";
			case r_earlier: return "move earlier";
			case r_later: return "move later";
			case r_delete: return "delete ring";

			case r_visEdit: return editorView.fieldVisibilityString();
			case r_typeEdit: return editorView.ringTypeString();
			case r_fontEdit: return "editing ...";
			case r_startEdit: return "editing ...";
			case r_endEdit: return "editing ...";
			case r_directionEdit: return editorView.ringDirectionString();
			case r_colorFilledEdit: return "editing ...";
			case r_colorUnfilledEdit: return "editing ...";
    	}
    	
    	return "unknown";
    }
    
    function onNext()
    {
    	switch (rState)
    	{
			case r_vis: rState = r_type; break;
			case r_type: rState = r_font; break;
			case r_font: rState = r_start; break;
			case r_start: rState = r_end; break;
			case r_end: rState = r_direction; break;
			case r_direction: rState = r_colorFilled; break;
			case r_colorFilled: rState = r_colorUnfilled; break;
			case r_colorUnfilled: rState = r_earlier; break;
			case r_earlier: rState = r_later; break;
			case r_later: rState = r_delete; break;
			case r_delete: break;

			case r_visEdit: editorView.fieldSetVisibility((editorView.fieldGetVisibility()+1)%25/*STATUS_NUM*/); break;
			case r_typeEdit: editorView.ringTypeEditing(1); break;
			case r_fontEdit: editorView.ringFontEditing(1); break;
			case r_startEdit: editorView.ringStartEditing(1); break;
			case r_endEdit: editorView.ringEndEditing(1); break;
			case r_directionEdit: editorView.ringDirectionEditing(); break;
			case r_colorFilledEdit: editorView.ringSetColorFilled((editorView.ringGetColorFilled()+1)%64); break;
			case r_colorUnfilledEdit: editorView.ringSetColorUnfilled((editorView.ringGetColorUnfilled()+1)%64); break;
    	}

   		return null;
    }
    
    function onPrevious()
    {
    	switch (rState)
    	{
			case r_vis: break;
			case r_type: rState = r_vis; break;
			case r_font: rState = r_type; break;
			case r_start: rState = r_font; break;
			case r_end: rState = r_start; break;
			case r_direction: rState = r_end; break;
			case r_colorFilled: rState = r_direction; break;
			case r_colorUnfilled: rState = r_colorFilled; break;
			case r_earlier: rState = r_colorUnfilled; break;
			case r_later: rState = r_earlier; break;
			case r_delete: rState = r_later; break;

			case r_visEdit: editorView.fieldSetVisibility((editorView.fieldGetVisibility()+25/*STATUS_NUM*/-1)%25/*STATUS_NUM*/); break;
			case r_typeEdit: editorView.ringTypeEditing(-1); break;
			case r_fontEdit: editorView.ringFontEditing(-1); break;
			case r_startEdit: editorView.ringStartEditing(-1); break;
			case r_endEdit: editorView.ringEndEditing(-1); break;
			case r_directionEdit: editorView.ringDirectionEditing(); break;
			case r_colorFilledEdit: editorView.ringSetColorFilled((editorView.ringGetColorFilled()+64-1)%64); break;
			case r_colorUnfilledEdit: editorView.ringSetColorUnfilled((editorView.ringGetColorUnfilled()+64-1)%64); break;
    	}

   		return null;
    }
    
    function onSelect()
    {
    	switch (rState)
    	{
			case r_vis: rState = r_visEdit; break;
			case r_type: rState = r_typeEdit; break;
			case r_font: rState = r_fontEdit; break;
			case r_start: rState = r_startEdit; break;
			case r_end: rState = r_endEdit; break;
			case r_direction: rState = r_directionEdit; break;
			case r_colorFilled: rState = r_colorFilledEdit; break;
			case r_colorUnfilled: rState = r_colorUnfilledEdit; break;
			case r_earlier: editorView.fieldEarlier(); break;
			case r_later: editorView.fieldLater(); break;
			case r_delete: editorView.fieldDelete(); return new myMenuItemFieldSelect();

			case r_visEdit: break;
			case r_typeEdit: break;
			case r_fontEdit: break;
			case r_startEdit: break;
			case r_endEdit: break;
			case r_directionEdit: break;
			case r_colorFilledEdit: break;
			case r_colorUnfilledEdit: break;
    	}
    	
    	return null;
    }
    
    function onBack()
    {
    	switch (rState)
    	{
			case r_vis:
			case r_type:
			case r_font:
			case r_start:
			case r_end:
			case r_direction:
			case r_colorFilled:
			case r_colorUnfilled:
			case r_earlier:
			case r_later:
			case r_delete:
				return new myMenuItemFieldSelect();

			case r_visEdit: rState = r_vis; break;
			case r_typeEdit: rState = r_type; break;
			case r_fontEdit: rState = r_font; break;
			case r_startEdit: rState = r_start; break;
			case r_endEdit: rState = r_end; break;
			case r_directionEdit: rState = r_direction; break;
			case r_colorFilledEdit: rState = r_colorFilled; break;
			case r_colorUnfilledEdit: rState = r_colorUnfilled; break;
    	}
    	
   		return null;
    }
}

(:m2app)
class myMenuItemSeconds extends myMenuItem
{
	enum
	{
		s_vis,
		s_font,
		s_refresh,
		s_color,
		s_color5,
		s_color10,
		s_color15,
		s_color0,
		s_delete,

		s_visEdit,
		s_fontEdit,
		s_refreshEdit,
		s_colorEdit,
		s_color5Edit,
		s_color10Edit,
		s_color15Edit,
		s_color0Edit,
	}

	var sState = s_vis;

	//visibility
	//font
	//refresh style
	//color
	//color5
	//color10
	//color15
	//color0

    function initialize()
    {   	
    	myMenuItem.initialize();
    }
    
    function getString()
    {
    	return "seconds data";
    }
    
    function onNext()
    {
   		return null;
    }
    
    function onPrevious()
    {
   		return null;
    }
    
    function onSelect()
    {
    	return null;
    }
    
    function onBack()
    {
   		return new myMenuItemFieldSelect();
    }
}

//class TestDelegate extends WatchUi.WatchFaceDelegate
//{
//    function initialize()
//    {
//        WatchFaceDelegate.initialize();
//    }
//
//    // The onPowerBudgetExceeded callback is called by the system if the
//    // onPartialUpdate method exceeds the allowed power budget. If this occurs,
//    // the system will stop invoking onPartialUpdate each second, so we set the
//    // partialUpdatesAllowed flag here to let the rendering methods know they
//    // should not be rendering a second hand.
//    function onPowerBudgetExceeded(powerInfo)
//    {
//        //System.println("Average execution time: " + powerInfo.executionTimeAverage);
//        //System.println("Allowed execution time: " + powerInfo.executionTimeLimit);
//    }
//}
