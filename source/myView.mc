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

	var isEditor = false;

	const GFX_VERSION = 0;			// a version number
	
	const PROFILE_NUM_USER = 24;		// number of user profiles
	//const PROFILE_NUM_PRESET = 17;		// number of preset profiles (in the jsondata resource)
	const PROFILE_NUM_PRESET = 1;		// number of preset profiles (in the jsondata resource)

	var displaySize = 240;
	var displayHalf = 120;

	var updateTimeNowValue;
	var updateTimeTodayValue;
	var updateTimeZoneOffset;

	var firstUpdateSinceInitialize = true;

	var settingsHaveChanged = false;
	
	var lastPartialUpdateSec;

	var glanceActive = false;
	
	var systemNumberMaxAscent;
	
	//enum
	//{
	//	//!APPCASE_ANY = 0,
	//	//APPCASE_UPPER = 1,
	//	//APPCASE_LOWER = 2
	//}
	
	// prop or "property" variables - are the ones which we store in onUpdate, so they don't change when they are used in onPartialUpdate
	//var propAddLeadingZero = false;

	var propBackgroundColor = 0x000000;
	var propForegroundColor = 0xFFFFFF;		// default foreground color
	//var propMenuColor = 0xFFFFFF;	// menu color editor only
	//var propMenuBorder = 0x000000;	// menu border editor only
	//var propFieldHighlight = 0xFFFFFF;	editor only
	//var propElementHighlight = 0xFFFFFF;	editor only
	var propKerningOn = true;
    var propBatteryHighPercentage = 75;
	var propBatteryLowPercentage = 25;
	var prop2ndTimeZoneOffset = 0;
    var propMoveBarAlertTriggerLevel = 1;

    var propFieldFontSystemCase = 0;	// 0, 1, 2
    var propFieldFontUnsupported = 1;	// 0=xtiny to 4=large

    var propSecondIndicatorOn = false;
	var propSecondResourceIndex = MAX_DYNAMIC_RESOURCES;
    var propSecondRefreshStyle = 0;
    var propSecondAligned = true;
	var propSecondColorIndexArray = new[60]b;
	var propSecondPositionsIndex = MAX_DYNAMIC_RESOURCES;
	var propSecondBufferIndex = MAX_DYNAMIC_RESOURCES;
	
	//enum
	//{
	//	REFRESH_EVERY_SECOND = 0,
	//	REFRESH_EVERY_MINUTE = 1,
	//	REFRESH_ALTERNATE_MINUTES = 2
	//}
    		    
	//const OUTER_FIRST_CHAR_ID = 21;
	//const OUTER_SIZE_HALF = 8;
	//const OUTER_CENTRE_OFFSET = 117;

	//const SECONDS_FIRST_CHAR_ID = 21;
	//const SECONDS_SIZE_HALF = 8;
	//!const SECONDS_CENTRE_OFFSET = SCREEN_CENTRE_X - SECONDS_SIZE_HALF;

	//const BUFFER_SIZE = 62;
	var bufferPositionCounter = -1;	// ensures buffer will get updated first time
	var bufferX = 0;
	var bufferY = 0;
	
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
	var hasTemperatureHistory;
	var hasHeartRateHistory;
	var hasFloorsClimbed;

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
	
//	//	FIELD_SHAPE_CIRCLE = 41,
//	//	//!FIELD_SHAPE_CIRCLE_SOLID = 42,
//	//	//!FIELD_SHAPE_ROUNDED = 43,
//	//	//!FIELD_SHAPE_ROUNDED_SOLID = 44,
//	//	//!FIELD_SHAPE_SQUARE = 45,
//	//	//!FIELD_SHAPE_SQUARE_SOLID = 46,
//	//	//!FIELD_SHAPE_TRIANGLE = 47,
//	//	//!FIELD_SHAPE_TRIANGLE_SOLID = 48,
//	//	//!FIELD_SHAPE_DIAMOND = 49,
//	//	//!FIELD_SHAPE_DIAMOND_SOLID = 50,
//	//	//!FIELD_SHAPE_STAR = 51,
//	//	//!FIELD_SHAPE_STAR_SOLID = 52,
//	//	//!FIELD_SHAPE_ALARM = 53,
//	//	//!FIELD_SHAPE_LOCK = 54,
//	//	//!FIELD_SHAPE_PHONE = 55,
//	//	//!FIELD_SHAPE_NOTIFICATION = 56,
//	//	//!FIELD_SHAPE_FIGURE = 57,
//	//	//!FIELD_SHAPE_BATTERY = 58,
//	//	//!FIELD_SHAPE_BATTERY_SOLID = 59,
//	//	//!FIELD_SHAPE_BED = 60,
//	//	//!FIELD_SHAPE_FLOWER = 61,
//	//	//!FIELD_SHAPE_FOOTSTEPS = 62,
//	//	//!FIELD_SHAPE_NETWORK = 63,
//	//	//!FIELD_SHAPE_STAIRS = 64,
//	//	//!FIELD_SHAPE_PHONE_HANDSET = 65,
//	//	//!FIELD_SHAPE_STOPWATCH = 66,
//	//	//!FIELD_SHAPE_FIRE = 67,
//	//	//!FIELD_SHAPE_HEART = 68,
//	//	//!FIELD_SHAPE_SUNRISE = 69,
//	//	//!FIELD_SHAPE_SUNSET = 70,
//	//	//!FIELD_SHAPE_SUN = 71,
//	//	//!FIELD_SHAPE_MOON = 72,
//	//	//!FIELD_SHAPE_MOUNTAIN = 73,

	//enum
	//{
	//	STATUS_ALWAYSON = 0,
	//	STATUS_GLANCE_ON = 1,
	//	STATUS_GLANCE_OFF = 2,
	//	STATUS_DONOTDISTURB_ON = 3,
	//	STATUS_DONOTDISTURB_OFF = 4,
	//	STATUS_ALARM_ON = 5,
	//	STATUS_ALARM_OFF = 6,
	//	STATUS_NOTIFICATIONS_PENDING = 7,
	//	STATUS_NOTIFICATIONS_NONE = 8,
	//	STATUS_PHONE_CONNECTED = 9,
	//	STATUS_PHONE_NOT = 10,
	//	STATUS_LTE_CONNECTED = 11,
	//	STATUS_LTE_NOT = 12,
	//	STATUS_BATTERY_HIGHORMEDIUM = 13,
	//	STATUS_BATTERY_HIGH = 14,
	//	STATUS_BATTERY_MEDIUM = 15,
	//	STATUS_BATTERY_LOW = 16,
	//	STATUS_MOVEBARALERT_TRIGGERED = 17,
	//	STATUS_MOVEBARALERT_NOT = 18,
	//	STATUS_AM = 19,
	//	STATUS_PM = 20,
	//	STATUS_2ND_AM = 21,
	//	STATUS_2ND_PM = 22,
	//	STATUS_SUNEVENT_RISE = 23,
	//	STATUS_SUNEVENT_SET = 24,
	//
	//	STATUS_NUM = 25
	//}
		
	var colorArray = new[64]b;

	const COLOR_NOTSET = -2;		// just used in the code to indicate no color set
	const COLOR_FOREGROUND = -1;	// use default foreground color

	//const COLOR_SAVE = 2;		// offset used when storing colors to gfx array
	//const COLOR_ONE = 1;		// used when editing colors to allow default foreground but not notset  
	
	function getColor64FromGfx(i)
	{
		i -= 2/*COLOR_SAVE*/;
	
		if (i<0 || i>=64)
		{
			return ((i==COLOR_FOREGROUND) ? propForegroundColor : COLOR_NOTSET); 
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
//							          // pale.......
//			//     20           21           22          23
//			// FF5500       FFAA00       FFFF55      AAFF55
//			(0x34<<24) | (0x38<<16) | (0x3D<<8) | (0x2D),
//			//     24           25           26          27
//			// 55FF55       55FFAA       55FFFF      55AAFF
//			(0x1D<<24) | (0x1E<<16) | (0x1F<<8) | (0x1B),
//			//     28           29           30          31
//			// 5555FF       AA55FF       FF55FF      FF55AA
//			(0x17<<24) | (0x27<<16) | (0x37<<8) | (0x36),
//									  // palest......
//			//     32           33           34          35
//			// FF5555       FFAA55       FFFFAA      AAFFAA
//			(0x35<<24) | (0x39<<16) | (0x3E<<8) | (0x2E),
//			//     36           37           38          39
//			// AAFFFF       AAAAFF       FFAAFF      FFAAAA
//			(0x2F<<24) | (0x2B<<16) | (0x3B<<8) | (0x3A),
//          // dim.......
//			//     40           41           42          43
//			// AAAA55       55AA55       55AAAA      5555AA
//			(0x29<<24) | (0x19<<16) | (0x1A<<8) | (0x16),
//									  // dark......
//			//     44           45           46          47
//			// AA55AA       AA5555       AAAA00      55AA00
//			(0x26<<24) | (0x25<<16) | (0x28<<8) | (0x18),
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

	//var circleFont;
	//var ringFont;

	//var worldBitmap;

	function getMinMax(v, min, max)
	{
		return (v<min) ? min : ((v>max) ? max : v);
	}

	function getMin(a, b)
	{
		return (a<b) ? a : b;
	}

	function getMax(a, b)
	{
		return (a>b) ? a : b;
	}

	function getNullCheckZero(v)
	{
		return ((v != null) ? v : 0);
	}

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
//			65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,
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
    	
    (:m2face)
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

    (:m2face)
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
    (:m2face)
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
    (:m2face)
	function propertiesGetTwoNumbers(p)
	{
		var charArray = propertiesGetCharArray(p);
		var charArraySize = charArray.size();
		parseIndex = 0;
		
		return parseTwoNumbers(charArray, charArraySize);
	}
	
	// Parse a time (hours & minutes) from a string
    (:m2face)
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
		hasTemperatureHistory = SensorHistory has :getTemperatureHistory;
		hasHeartRateHistory = SensorHistory has :getHeartRateHistory;
		hasFloorsClimbed = ActivityMonitor.Info has :floorsClimbed;

		displaySize = dc.getWidth();
		displayHalf = displaySize/2;

		// need to seed the random number generator?
		//var clockTime = System.getClockTime();
		//var seed = clockTime.sec + clockTime.min*60 + clockTime.hour*(60*60) + System.getTimer();
		//Math.srand(seed);
				
        //circleFont = WatchUi.loadResource(fonts.id_circle);
        //ringFont = WatchUi.loadResource(fonts.id_ring);

		//worldBitmap = WatchUi.loadResource(Rez.Drawables.id_world);

		// load in permanent global custom data
//		{
//			var dataResource = watchUi.loadResource(Rez.JsonData.id_custom);
//		}

//System.println("Timer json1=" + (System.getTimer()-timeStamp) + "ms");
		
		// load in character string (for seconds & outer ring)
		//characterString = WatchUi.loadResource(Rez.JsonData.id_characterString);

//var prevMem = System.getSystemStats().freeMemory; 
//var myTestResource = watchUi.loadResource(Rez.JsonData.id_colorStrings3);
//var curMem = System.getSystemStats().freeMemory; 
//System.println("myTestResource=" + (prevMem-curMem));
//myTestResource = null;

		{
			// load in global data
			var dataResource = watchUi.loadResource(Rez.JsonData.id_data);
			
			// keep pointers to permanent arrays
			kernTable = dataResource[0];
			bitsSupported = dataResource[1];

			// copy byte data into byte arrays (to save memory) 			
			for (var i=0; i<95; i++)
			{
				dynResSizeArray[i] = dataResource[6][i];

				if (i<78)
				{
					myChars[i] = dataResource[2][i];	// table for characters with diacritics
	
					if (i<64)
					{
						colorArray[i] = dataResource[3][i];
	
						if (i<25/*SECONDFONT_UNUSED*/)
						{
							dynResOuterSizeArray[i] = dataResource[7][i];

							if (i<10/*GFX_SIZE_NUM*/*2)
							{
								gfxSizeArray[i] = dataResource[4][i];
							}
						}
					}
				}
			}
			
			// copy single value
			systemNumberMaxAscent = dataResource[5][0];

			dataResource = null;	// release the memory
		}

//System.println("Timer json2=" + (System.getTimer()-timeStamp) + "ms");

		var timeNowValue = Time.now().value();

		initHeartSamples(timeNowValue);

		// remember which profile was active and also any profileDelayEnd value
		loadMemoryData(timeNowValue);
		
//System.println("Timer loadmem=" + (System.getTimer()-timeStamp) + "ms");

		loadProfileTimeData();		// load profile times
		
//System.println("Timer loadprof=" + (System.getTimer()-timeStamp) + "ms");

		//gfxDemo();
    }

	// called from the app when it is being ended
	function onStop()
	{
        //System.println("onStop");

		// remember the active profile and profileDelayEnd and other variables we want to save between runs
		saveMemoryData();
	}

    // Called when this View is brought to the foreground.
    // Restore the state of this View and prepare it to be shown. This includes loading resources into memory.
    function onShow()
    {
        //System.println("onShow");
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
	}
	
    (:m2app)
	function getSettingsForFaceOrApp()
	{
	}
	
	function getPresetProfileString(profileIndex, n)
	{
		var jsonData = Rez.JsonData;
		var loadPreset = [jsonData.id_preset0, jsonData.id_preset1, jsonData.id_preset2, jsonData.id_preset3, jsonData.id_preset4, jsonData.id_preset5, jsonData.id_preset6, jsonData.id_preset7, jsonData.id_preset8, jsonData.id_preset9, jsonData.id_preset10, jsonData.id_preset11, jsonData.id_preset12, jsonData.id_preset13, jsonData.id_preset14, jsonData.id_preset15, jsonData.id_preset16];
		return ((profileIndex>=PROFILE_NUM_USER && profileIndex<(PROFILE_NUM_USER+PROFILE_NUM_PRESET)) ? WatchUi.loadResource(loadPreset[profileIndex - PROFILE_NUM_USER])[n] : "");
	}

	function getProfileString(profileIndex)
	{
		return ((profileIndex<PROFILE_NUM_USER) ? applicationStorage.getValue("P" + profileIndex) : getPresetProfileString(profileIndex, 1));
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
			var days = profileTimeData[profileIndex*6 + 2];		
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
	
			var startTime = profileTimeData[profileIndex*6 + 0];
			var endTime = profileTimeData[profileIndex*6 + 1];
			var profileFlags = profileTimeData[profileIndex*6 + 3];
			applicationProperties.setValue("PS", profileTimeString(startTime, (profileFlags&0x01/*PROFILE_START_SUNRISE*/)!=0, (profileFlags&0x02/*PROFILE_START_SUNSET*/)!=0));
			applicationProperties.setValue("PE", profileTimeString(endTime, (profileFlags&0x04/*PROFILE_END_SUNRISE*/)!=0, (profileFlags&0x08/*PROFILE_END_SUNSET*/)!=0));

			applicationProperties.setValue("35", (profileTimeData[profileIndex*6 + 5] >= 0) ? (profileTimeData[profileIndex*6 + 5] + 1) : "");		// glance profile

			applicationProperties.setValue("PB", ((profileFlags&0x10/*PROFILE_BLOCK_MASK*/)!=0));
			applicationProperties.setValue("PR", profileTimeData[profileIndex*6 + 4]);		
		}
	}

	(:m2face)		
	function getProfileTimeDataFromPropertiesFaceOrApp(profileIndex)
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
			profileTimeData[profileIndex*6 + 2] = days;

			var startTime = propertiesGetTime("PS");
			var endTime = propertiesGetTime("PE");
			profileTimeData[profileIndex*6 + 0] = startTime[1];		// start time
			profileTimeData[profileIndex*6 + 1] = endTime[1];		// end time
			
			profileTimeData[profileIndex*6 + 5] = propertiesGetNumber("35") - 1;	// glance profile

			var profileFlags = ((startTime[0] & 0x03) | ((endTime[0] & 0x03) << 2));
			if (propertiesGetBoolean("PB"))
			{
				profileFlags |= 0x10/*PROFILE_BLOCK_MASK*/;
			}
			profileTimeData[profileIndex*6 + 3] = profileFlags;

			profileTimeData[profileIndex*6 + 4] = getMinMax(propertiesGetNumber("PR"), 0, 0xFF/*PROFILE_EVENTS_MASK*/);
		}
	}
	
	(:m2app)		
	function setProfilePropertiesFaceOrApp(profileIndex)
	{
	}
	
	(:m2app)		
	function getProfileTimeDataFromPropertiesFaceOrApp(profileIndex)
	{
	}
	
	function loadProfile(profileNumber)
	{
		if (profileNumber>=0 && profileNumber<(PROFILE_NUM_USER+PROFILE_NUM_PRESET))
		{
			var s = getProfileString(profileNumber);
			if (s!=null && (s instanceof String))
			{
				if (s.length()>255)
				{
					applicationProperties.setValue("EP2", s.substring(255, s.length()));					
					s = s.substring(0, 255);
				}
				else
				{ 				
					applicationProperties.setValue("EP2", "");
				}
			
				applicationProperties.setValue("EP", s);
			}

			setProfilePropertiesFaceOrApp(profileNumber);
		}
	}
	
	function saveProfile(profileNumber)
	{
		if (profileNumber>=0 && profileNumber<PROFILE_NUM_USER)
		{
			var s = propertiesGetString("EP") + propertiesGetString("EP2");
			applicationStorage.setValue("P" + profileNumber, s);
			s = null;

			getProfileTimeDataFromPropertiesFaceOrApp(profileNumber);
			saveProfileTimeData();		// remember new values
		}
	}
	
	function copyPropertyStringToGfx()
	{
		// load the Gfx from our property strings
		var s = propertiesGetString("EP") + propertiesGetString("EP2");
		var charArray = s.toCharArray();
		s = null;
		gfxFromCharArray(charArray);
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

			getProfileTimeDataFromPropertiesFaceOrApp(profileActive);
			saveProfileTimeData();		// remember new values
		}
		else
		{
			applicationProperties.setValue("PM", 0);

			if (profileManagement == 1)			// load from profile
			{
				loadProfile(profileNumber);
			}
			else if (profileManagement == 2)	// save to profile
			{
				saveProfile(profileNumber);
			}

			profileActive = profileNumber;		// set the active profile number

			profileDelayEnd = updateTimeNowValue + ((60-second)%60) + 2*60;		// delay of 2 minutes before any auto profile switching
			profileRandomEnd = 0;							// clear this
			demoProfilesCurrentEnd = 0;
		}
	}
		
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
    
//	function printMem(s)
//	{
//		var stats = System.getSystemStats();
//		System.println("free=" + stats.freeMemory + " " + s);
//	}
    
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

			loadProfile(profileToActivate);

			profileActive = profileToActivate;		// set the active profile number

			applicationProperties.setValue("PN", profileToActivate+1);		// set the profile number

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
			copyPropertyStringToGfx();

			gfxAddDynamicResources(-1);
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
		bufferPositionCounter = -1;		// clear any background buffer being known

		// draw the seconds indicator to the screen
		if (propSecondIndicatorOn && doDrawGfx)
		{
        	if (propSecondRefreshStyle==0/*REFRESH_EVERY_SECOND*/)
        	{
        		var s = (propSecondAligned ? second : (second+59)%60); 
   				drawSecond(dc, s, s);
    		}
    		else if ((propSecondRefreshStyle==1/*REFRESH_EVERY_MINUTE*/) || (propSecondRefreshStyle==2/*REFRESH_ALTERNATE_MINUTES*/ && (minute%2)==0))
    		{
    			// draw all the seconds up to this point in the minute
				drawSecond(dc, 0, propSecondAligned ? second : (second-1));
    		}
    		else if (propSecondRefreshStyle==2/*REFRESH_ALTERNATE_MINUTES*/ && (minute%2)==1)
			{
				if (propSecondAligned)
				{
					// always draw indicator at 0 in this mode
					// (it covers up frame slowdown when drawing all the rest of the seconds coming next ...)
   					drawSecond(dc, 0, 0);

   				}

    			// draw all the seconds after this point in the minute
   				drawSecond(dc, propSecondAligned ? (second+1) : second, 59);
    		}
		}
    }

	var doDrawGfx = true;

	function drawBackgroundToDc(useDc)
	{ 
		var dcX;
		var dcY;

		var toBuffer = (useDc==null);
		if (toBuffer)	// offscreen buffer
		{
			var bufferBitmap = getDynamicResource(propSecondBufferIndex);
			if (bufferBitmap==null)
			{
				return;
			}
		
			useDc = bufferBitmap.getDc();
			dcX = bufferX;
			dcY = bufferY;
		}
		else
		{
			dcX = 0;
			dcY = 0;
		}

    	// reset to the background color
		useDc.clearClip();
	    useDc.setColor(-1/*COLOR_TRANSPARENT*/, propBackgroundColor);
		// test draw background of offscreen buffer in a different color
		//if (toBuffer)
		//{
	    //	useDc.setColor(-1/*COLOR_TRANSPARENT*/, getColor64FromGfx(2/*COLOR_SAVE*/+4+42+(bufferPositionCounter*4)%12));
		//}
        useDc.clear();
		
		if (doDrawGfx)
		{
			gfxDrawBackground(useDc, dcX, dcY, toBuffer);
		}
	}

    (:m2face)
	function drawBuffer(secondsIndex, dc)
	{
		var dynamicPositions = getDynamicResource(propSecondPositionsIndex);
		if (dynamicPositions!=null)		// sometimes onPartialUpdate is called between onSettingsChanged and onUpdate - so this resource could be null
		{
		    var doUpdate = (bufferPositionCounter < 0);	// if no buffer yet
		    
			//var xCur = getOuterX(dynamicPositions, secondsIndex);		// calling these functions is a lot more expensive in partial update watchface diagnostics
			//var yCur = getOuterY(dynamicPositions, secondsIndex);
			var xyVal = dynamicPositions[secondsIndex];
			var xCur = (xyVal & 0xFFFF);
			var yCur = ((xyVal>>16) & 0xFFFF);
			//var secondsSizeHalf = getOuterSizeHalf(dynamicPositions);
			var secondsSizeHalf = dynamicPositions[61];
	
		    if (!doUpdate)
		    {
				// see if need to redraw the offscreen buffer (if clearIndex is outside it)
				doUpdate = ((xCur<bufferX+secondsSizeHalf) || (xCur>bufferX-secondsSizeHalf+62/*BUFFER_SIZE*/) || 
							(yCur<bufferY+secondsSizeHalf) || (yCur>bufferY-secondsSizeHalf+62/*BUFFER_SIZE*/));
			}
	
		    if (doUpdate)
		    {
				var xMin = xCur;
				var xMax = xCur;
				var yMin = yCur;
				var yMax = yCur;
	
				var r = 62/*BUFFER_SIZE*/-secondsSizeHalf*2;
	
		    	for (var i=secondsIndex+1; i<60; i++)
		    	{
		    		//var x = getOuterX(dynamicPositions, i);		// calling these functions is a lot more expensive in partial update watchface diagnostics
		    		//var y = getOuterY(dynamicPositions, i);
					var xyVal = dynamicPositions[i];
					var x = (xyVal & 0xFFFF);
					var y = ((xyVal>>16) & 0xFFFF);
		    		
		    		// stop at second which can't fit inside buffer
		    		if ((x-xMin)>r || (xMax-x)>r || (y-yMin)>r || (yMax-y)>r)
		    		{
		    			break;
		    		}
		    		
		    		// remember new max limits
		    		if (x<xMin)
		    		{
		    			xMin = x;
		    		}
		    		else if (x>xMax)
		    		{
		    			xMax = x;
		    		}
		    		
		    		if (y<yMin)
		    		{
		    			yMin = y;
		    		}
		    		else if (y>yMax)
		    		{
		    			yMax = y;
		    		}
		    	}
		    
		    	// shift buffer to the outside as much as possible while still fitting valid seconds
				bufferX = ((xMin>displayHalf) ? (xMin-secondsSizeHalf) : (xMax+secondsSizeHalf-62/*BUFFER_SIZE*/)); 
				bufferY = ((yMin>displayHalf) ? (yMin-secondsSizeHalf) : (yMax+secondsSizeHalf-62/*BUFFER_SIZE*/));
		    
				bufferPositionCounter++;		// set the buffer we are using
					
				drawBackgroundToDc(null);	// and draw the background into the buffer
		
				// test draw the offscreen buffer to see what is in it
		    	//dc.setClip(bufferX, bufferY, 62/*BUFFER_SIZE*/, 62/*BUFFER_SIZE*/);
				//dc.drawBitmap(bufferX, bufferY, bufferBitmap);
		    	//dc.clearClip();
	
				// draw a rect showing position of buffer
		    	//dc.setClip(bufferX, bufferY, 62/*BUFFER_SIZE*/, 62/*BUFFER_SIZE*/);
			    //dc.setColor(-1/*COLOR_TRANSPARENT*/, getColor64FromGfx(2/*COLOR_SAVE*/+4+42+(bufferPositionCounter*4)%12));
		        //dc.clear();
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
    		var refreshAlternateClearing = (propSecondRefreshStyle==2/*REFRESH_ALTERNATE_MINUTES*/ && (minuteIndex%2)==1);
    	
 			var clearIndex;
	    	if (propSecondRefreshStyle==0/*REFRESH_EVERY_SECOND*/)
	    	{
	        	// Clear the previous second indicator we drew and restore the background
        		clearIndex = (propSecondAligned ? lastPartialUpdateSec : (lastPartialUpdateSec+59)%60); 
	    	}
	    	else if (refreshAlternateClearing)
	    	{
	        	clearIndex = (propSecondAligned ? secondsIndex : (secondsIndex-1));
			}
			else
			{
				clearIndex = -1;
			}

	        if (clearIndex>=0)
	        {
				var bufferBitmap = getDynamicResource(propSecondBufferIndex);
		        if (bufferBitmap!=null)
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

					if (refreshAlternateClearing)
					{
						// redraw the indicator following the one we just cleared
						// as some of it might have been erased
						// - but need to keep using the clip region we used for the erase above
						var nextIndex = (clearIndex+1)%60; 
						drawSecond(dc, nextIndex, nextIndex);
			
						// in this mode we also always draw the indicator at 0
						// - so check if that needs redrawing too after erasing the indicator at 1
						if (propSecondAligned && clearIndex==1)
						{
							drawSecond(dc, 0, 0);
						}
					}
		       	}
			}
			
			// now draw the correct second
			if (!refreshAlternateClearing)
			{
        		var s = (propSecondAligned ? secondsIndex : (secondsIndex+59)%60); 
    			setSecondClip(dc, s);
   				drawSecond(dc, s, s);
			}
		}
    }

    (:m2face)
    function setSecondClip(dc, index)
    {
		var dynamicPositions = getDynamicResource(propSecondPositionsIndex);
		if (dynamicPositions!=null)		// sometimes onPartialUpdate is called between onSettingsChanged and onUpdate - so this resource could be null
		{
    		//var x = getOuterX(dynamicPositions, index);		// calling these functions is a lot more expensive in partial update watchface diagnostics
    		//var y = getOuterY(dynamicPositions, index);
			var xyVal = dynamicPositions[index];
			var x = (xyVal & 0xFFFF);
			var y = ((xyVal>>16) & 0xFFFF);
			//var secondsSizeHalf = getOuterSizeHalf(dynamicPositions);
			var secondsSizeHalf = dynamicPositions[61];
   			dc.setClip(x-secondsSizeHalf, y-secondsSizeHalf, secondsSizeHalf*2, secondsSizeHalf*2);
   		}
    }

    function drawSecond(dc, startIndex, endIndex)
    {
		var dynamicResource = getDynamicResource(propSecondResourceIndex);
		var dynamicPositions = getDynamicResource(propSecondPositionsIndex);
		if (dynamicResource!=null && dynamicPositions!=null)		// sometimes onPartialUpdate is called between onSettingsChanged and onUpdate - so this resource could be null
		{
			//var secondsSizeHalf = getOuterSizeHalf(dynamicPositions);
			var secondsSizeHalf = dynamicPositions[61];

	    	var curCol = COLOR_NOTSET;
	    	for (var index=startIndex; index<=endIndex; index++)
	    	{
	    		// show second clip region
	    		//if (bufferPositionCounter>=0)
	    		//{
			    // 	dc.setColor(-1/*COLOR_TRANSPARENT*/, Graphics.COLOR_RED);
			    // 	dc.clear();
			    //}
	    	
				var col = getColor64FromGfx(propSecondColorIndexArray[index]);
		
		        if (curCol != col)
		        {
		        	curCol = col;
		       		dc.setColor(curCol, -1/*COLOR_TRANSPARENT*/);	// seconds color
		       	}
		       	//dc.setColor(col, Graphics.COLOR_RED);	// show background of whole font character
		       	//dc.setColor(getColor64FromGfx(2/*COLOR_SAVE*/+4+42+(index*4)%12), -1/*COLOR_TRANSPARENT*/);

	    		//var x = getOuterX(dynamicPositions, index);		// calling these functions is a lot more expensive in partial update watchface diagnostics
	    		//var y = getOuterY(dynamicPositions, index);
				var xyVal = dynamicPositions[index];
				var x = (xyVal & 0xFFFF);
				var y = ((xyVal>>16) & 0xFFFF);
	
		       	//var s = characterString.substring(index+9, index+10);
				//var s = StringUtil.charArrayToString([(index + SECONDS_FIRST_CHAR_ID).toChar()]);
				//var s = (index + 21/*SECONDS_FIRST_CHAR_ID*/).toChar().toString();
				// need to draw 1 pixel higher than expected ...
	        	dc.drawText(x-secondsSizeHalf, y-secondsSizeHalf-1, dynamicResource, (index + 21/*SECONDS_FIRST_CHAR_ID*/).toChar().toString(), 2/*TEXT_JUSTIFY_LEFT*/);
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
				if (profileActive>=0 && profileActive<PROFILE_NUM_USER && profileTimeData[profileActive*6 + 5]>=0 && profileTimeData[profileActive*6 + 5]<(PROFILE_NUM_USER+PROFILE_NUM_PRESET))
				{
					doActivate = profileTimeData[profileActive*6 + 5];
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
			var autoActivate = -1;		// not found one to activate yet

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
				if (autoActivate<0)	// not found a profile to activate yet
				{
					var startTime = profileTimeData[i*6 + 0];
					var endTime = profileTimeData[i*6 + 1];

					// see if the start or end time uses sunrise/sunset					
					if ((profileTimeData[i*6 + 3]&(0x01/*PROFILE_START_SUNRISE*/|0x02/*PROFILE_START_SUNSET*/|0x04/*PROFILE_END_SUNRISE*/|0x08/*PROFILE_END_SUNSET*/))!=0)
					{
						calculateSun(dateInfoShort);
						
						startTime = getProfileSunTime(startTime, profileTimeData[i*6 + 3], 0);
						endTime = getProfileSunTime(endTime, profileTimeData[i*6 + 3], 2);
					}
					
					var dayFlags = profileTimeData[i*6 + 2];
					if (startTime<endTime)		// Note: if 2 times are equal then go for 24 hours (e.g. by default both times are 0)
					{
						if (timeNowInMinutesToday>=startTime && timeNowInMinutesToday<endTime && (dayFlags&(0x01<<nowDayNumber))!=0)	// current day set?
						{
							autoActivate = i;
						}
					}
					else
					{
						// goes over midnight
						if ((timeNowInMinutesToday>=startTime && (dayFlags&(0x01<<nowDayNumber))!=0) ||			// current day 
							(timeNowInMinutesToday<endTime && (dayFlags&(0x01<<prevDayNumber))!=0))				// previous day
						{
							autoActivate = i;
						}
					}
				}

				var numEvents = profileTimeData[i*6 + 4];
				if (numEvents>0)
				{
					randomProfiles[randomNum] = i;
					randomEvents[randomNum] = numEvents;
					randomEventsTotal += numEvents;
					randomNum++;
				}
			}
			
			if (autoActivate>=0)
			{
				doActivate = autoActivate;
			}
			
			// check for random activates
			if (doActivate>=0 && doActivate<PROFILE_NUM_USER && (profileTimeData[doActivate*6 + 3]&0x10/*PROFILE_BLOCK_MASK*/)==0)
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
				if (autoActivate>=0)
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
	
	var appWantsToLoadProfile = -1;
	
	(:m2app)
	function checkProfileToActivate(timeNow)
	{
		if (appWantsToLoadProfile>=0)
		{
			profileActive = -1;

			var temp = appWantsToLoadProfile;
			appWantsToLoadProfile = -1;
			return temp;
		}
		else
		{
			return profileActive;
		}
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

	//const heartChartHeight = 20+1;
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
			// h+1 so it goes to same position as axes (for alignment with text when no axes drawn)
			var h = getMinMax((heartDisplayBins[i]*21/*heartChartHeight*/)/heartMaxZone5, 0, 21/*heartChartHeight*/-1) + 1;

			useDc.fillRectangle(x + 4/*heartOneBarWidth*/*i, y - h, 4/*heartOneBarWidth*/-1, h);
			//useDc.drawPoint(100+x - dcX, 220-h - dcY);
			//useDc.drawLine(i, 0, i, 30);
		}

		if (axesSide || axesBottom)
		{
			useDc.setColor(colorAxes, -1/*COLOR_TRANSPARENT*/);

			if (axesSide)
			{	
				// draw the axes
				useDc.fillRectangle(x-2, y - 21/*heartChartHeight*/, 1, 21/*heartChartHeight*/);				// left
				useDc.fillRectangle(x+(4/*heartOneBarWidth*/*12/*heartNumBins*/), y-21/*heartChartHeight*/, 1, 21/*heartChartHeight*/);		// right
			}
	
			if (axesBottom)
			{
				useDc.fillRectangle(x+(axesSide?-1:0), y-1, (4/*heartOneBarWidth*/*12/*heartNumBins*/)+(axesSide?1:-1), 1);				// bottom
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

	(:m2face)
	var profileTimeData = new[PROFILE_NUM_USER*6];
	
	(:m2face)
	function loadProfileTimeData()
	{
		var charArray = propertiesGetCharArray("sd");

		valDecodeArray(profileTimeData, PROFILE_NUM_USER*6, charArray, charArray.size());

		//System.println("profileTimeData=" + profileTimeData.toString());
	}
	
	(:m2face)
	function saveProfileTimeData()
	{
		var tempCharArray = new[PROFILE_NUM_USER*6*2];
		valEncodeArray(profileTimeData, PROFILE_NUM_USER*6, tempCharArray, PROFILE_NUM_USER*6*2);
		
		applicationProperties.setValue("sd", StringUtil.charArrayToString(tempCharArray));
	}

	(:m2app)
	function loadProfileTimeData()
	{
	}
	
	(:m2app)
	function saveProfileTimeData()
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
	// 2 = large (hour, minute, colon)
	// 3 = string
	// 4 = icon
	// 5 = movebar
	// 6 = chart
	// 7 = rectangle
	// 8 = ring
	// 9 = seconds

	const MAX_GFX_DATA = 500;

	var gfxNum = 0;
	var gfxData = new[MAX_GFX_DATA];

	(:m2app)
	function getUsedGfxData()
	{
		return gfxNum.toFloat()/MAX_GFX_DATA;
	}

	const MAX_GFX_CHARS = 150;

	var gfxCharArray = new[MAX_GFX_CHARS];
	var gfxCharArrayLen = 0;

	(:m2app)
	function getUsedCharArray()
	{
		return gfxCharArrayLen.toFloat()/MAX_GFX_CHARS;
	}

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
	
	(:m2face)
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

	(:m2face)
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

	(:m2app)
	function gfxToCharArray()
	{
		var charArray = new[MAX_PROFILE_STRING_LENGTH];
		var charArrayLen = 0;
	
		//System.println("gfxNum=" + gfxNum);

		for (var index=0; index<gfxNum; )
		{
			//var id = getGfxId(index);
			var id = (gfxData[index] & 0xFF);	// cheaper with no function call in loop
		
			var curLen = charArrayLen;
		
			//var saveSize = gfxSizeSave(id);
			if (id<0 || id>=10/*GFX_SIZE_NUM*/)
			{
				break;
			}
			var saveSize =  gfxSizeArray[id*2 + 1];	// cheaper with no function call in loop
			for (var i=0; i<saveSize; i++)
			{
				var val = gfxData[index+i] & 0xFFFF;
				
				// 0-9 a-z A-Z
				// 10 +26 +26 =62
				// 62*62=3844, so 0-3843				
				// but use the top bit to indicate if it is 1 or 2 bytes (so half that range is 0-1921)
				
				//System.print("" + val);

				if (val<31)
				{
					if (curLen<MAX_PROFILE_STRING_LENGTH)
					{
						charArray[curLen] = valEncodeChar(val);
						//System.print("[" + c.toString() + "], ");
					}
					curLen++;
				}
				else
				{
					if (curLen<MAX_PROFILE_STRING_LENGTH-1)
					{
						var v0 = val/62 + 31;
						var v1 = val%62;
						
						charArray[curLen] = valEncodeChar(v0);
						//System.print("[" + c.toString() + "+");
	
						charArray[curLen+1] = valEncodeChar(v1);
						//System.print("" + c.toString() + "], ");
					}
					curLen+=2;
				}
			}		
		
			// check we haven't reached the max profile string length
			if (curLen<=MAX_PROFILE_STRING_LENGTH)
			{
				charArrayLen = curLen;
				
				//index += gfxSize(id);
				//if (id<0 || id>=10/*GFX_SIZE_NUM*/)	this is checked above already
				//{
				//	break;
				//}
				index += gfxSizeArray[id*2]; 	// cheaper with no function call in loop
			}
			else
			{
				break;	// not space to add more				
			}
		}

		//System.println("");
		
		return charArray.slice(0, charArrayLen);
	}

	function gfxFromCharArray(charArray)
	{
		var gotError = false;
		var charArraySize = charArray.size();

		gfxNum = 0;

		for (var index=0; index<charArraySize && !gotError; )
		{
			var id = 0;
			var itemSize = 0;
			
			var saveSize = 1;
			for (var i=0; i<saveSize; i++)
			{
				if (index>=charArraySize)
				{
					gotError = true;
					break;
				}

				var v = valDecodeChar(charArray[index]);
				index++;

				if (v>=31)
				{
					if (index>=charArraySize)
					{
						gotError = true;
						break;
					}

					var v1 = valDecodeChar(charArray[index]);
					index++;
					v = (v-31)*62 + v1;
				}

				//System.print("" + v + ", ");

				if (i==0)
				{
					id = (v & 0xFF);
										
					//itemSize = gfxSize(id);		// total item size in gfxData array
					if (id<0 || id>=10/*GFX_SIZE_NUM*/)
					{
						gotError = true;
						break; 
					}
					itemSize = gfxSizeArray[id*2]; 	// cheaper with no function call in loop
					
					//saveSize = gfxSizeSave(id);	// number of bytes to read from saved data
					saveSize = gfxSizeArray[id*2 + 1];	// cheaper with no function call in loop

					if (itemSize<=0)
					{
						gotError = true;
						break; 
					}
					
					// check the size of this item will fit into the gfxData array
					if (gfxNum+itemSize > MAX_GFX_DATA)
					{
						// don't force an error & blank profile, but stop reading data
						itemSize = 0;
						break;
					}
				}

				gfxData[gfxNum + i] = v;
			}
			
			gfxNum += itemSize;		// only once item fully added successfully do we increase size of array
		}

		if (gotError || gfxNum<gfxSize(0) || getGfxId(0)!=0)	// check no error and header gfx at start
		{
			gfxNum = 0; 
			gfxAddHeader(gfxNum);	
		}

		//System.println("");
	}

	function getGfxId(index)
	{
		return (gfxData[index] & 0xFF);
	}

	//const GFX_SIZE_NUM = 10;
	var gfxSizeArray = new[10/*GFX_SIZE_NUM*/*2]b;

	function gfxSize(id)
	{
		return ((id<0 || id>=10/*GFX_SIZE_NUM*/) ? 0 : gfxSizeArray[id*2]); 
	}

	function gfxSizeSave(id)
	{
		return ((id<0 || id>=10/*GFX_SIZE_NUM*/) ? 0 : gfxSizeArray[id*2 + 1]);
	}

	function gfxInsert(index, id)
	{
		var size = gfxSize(id);

		if (gfxNum+size > MAX_GFX_DATA)		// check enough space in gfxData for new item
		{
			index = -1;		// no space
		}
		else
		{
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
		
		return index;	// return successful index we inserted at (or -1 if no space)
	}

	function gfxAddHeader(index)
	{
		index = gfxInsert(index, 0);
		if (index>=0)
		{
			gfxData[index+1] = GFX_VERSION;	// version
			gfxData[index+2] = displaySize;	// watch display size
			gfxData[index+3] = 0+2/*COLOR_SAVE*/;	// background color
			gfxData[index+4] = 3+2/*COLOR_SAVE*/;	// foreground color
			gfxData[index+5] = 3+2/*COLOR_SAVE*/;	// menu color
			gfxData[index+6] = 0+2/*COLOR_SAVE*/;	// menu border
			gfxData[index+7] = COLOR_FOREGROUND+2/*COLOR_SAVE*/;	// field highlight
			gfxData[index+8] = COLOR_FOREGROUND+2/*COLOR_SAVE*/;	// element highlight
			gfxData[index+9] = 1;	// kerning on for large fonts
	    	gfxData[index+10] = 75;	// propBatteryHighPercentage, 0 to 100
	    	gfxData[index+11] = 25;	// propBatteryLowPercentage, 0 to 100
			gfxData[index+12] = 24; // prop2ndTimeZoneOffset, 24==0 (0 to 48)
    		gfxData[index+13] = 1;	// propMoveBarAlertTriggerLevel, 1 to 5
    		gfxData[index+14] = 0; 	// propFieldFontSystemCase (0=any, 1=upper, 2=lower)
    		gfxData[index+15] = 1;	// propFieldFontUnsupported (0=xtiny to 4=large)
			//gfxData[index+9] = 0;	// default field font
		}
		return index;
	}

	// seconds, ring, hour, minute, icon, field
	const MAX_DYNAMIC_RESOURCES = 30;
	const BUFFER_RESOURCE = 0x8FFFFFFF;
	
	var dynResNum = 0;
	var dynResList = new[MAX_DYNAMIC_RESOURCES];
	var dynResResource = new[MAX_DYNAMIC_RESOURCES];

	(:m2app)
	function getUsedDynamicResourceNum()
	{
		return dynResNum.toFloat()/MAX_DYNAMIC_RESOURCES;
	}

	const MAX_DYNAMIC_MEM = 500;
	var dynResMem50 = 0;
	var dynResMemFailed = false;

	(:m2app)
	function getUsedResourceMemory()
	{
		return (dynResMemFailed ? 1.0 : (dynResMem50.toFloat()/MAX_DYNAMIC_MEM));
	}

	function addDynamicResource(r, m)
	{
		var i = dynResList.indexOf(r);
		if (i>=0)
		{
			return i;
		}
	
		if (dynResNum<MAX_DYNAMIC_RESOURCES)
		{
			if ((dynResMem50+m)<=MAX_DYNAMIC_MEM)
			{
				dynResList[dynResNum] = r;
				dynResNum++;
	
				dynResMem50 += m;
				
				return dynResNum-1;
			}
			else
			{
				dynResMemFailed = true;
			}
		}
		
		return MAX_DYNAMIC_RESOURCES;
	}

    function releaseDynamicResources()
    {
		for (var i=0; i<dynResNum; i++)
		{
			dynResList[i] = null;
			dynResResource[i] = null;
		}
		
		dynResNum = 0;

    	propSecondIndicatorOn = false;
		propSecondResourceIndex = MAX_DYNAMIC_RESOURCES;
		propSecondPositionsIndex = MAX_DYNAMIC_RESOURCES;
		propSecondBufferIndex = MAX_DYNAMIC_RESOURCES;
    }

    function loadDynamicResources()
    {
//		var prevMem = System.getSystemStats().freeMemory; 
//		System.println("loadDynamicResources free=" + prevMem);
    
		for (var i=0; i<dynResNum; i++)
		{
			var r = dynResList[i];
			if (r==BUFFER_RESOURCE)
			{
		        // If this device supports BufferedBitmap, allocate the buffer for what's behind the seconds indicator 
		        //if (Toybox.Graphics has :BufferedBitmap)
				// This full color buffer is needed because anti-aliased fonts cannot be drawn into a buffer with a reduced color palette
				dynResResource[i] = new Graphics.BufferedBitmap({:width=>62/*BUFFER_SIZE*/, :height=>62/*BUFFER_SIZE*/});
			}
			else
			{
				dynResResource[i] = (isDynamicResourceSystemFont(i) ? r : WatchUi.loadResource(r));
			}

//	    	var curMem = System.getSystemStats().freeMemory; 
//	    	System.println("" + i + " = " + (prevMem-curMem) + " (" + ((prevMem-curMem+49)/50) + ")");
//	    	prevMem = curMem;
		}
    }
    
	function getDynamicResource(i)
	{
		return ((i<dynResNum) ? dynResResource[i] : null);
	}

//	function getDynamicResourceAscent(i)
//	{
//		return ((i<dynResNum) ? Graphics.getFontAscent(dynResResource[i]) : 0);
//	}

//	function getDynamicResourceDescent(i)
//	{
//		return ((i<dynResNum) ? Graphics.getFontDescent(dynResResource[i]) : 0);
//	}

	function updateFieldMaxAscentDescentResource(val, i)
	{
		if (i>=0 && i<dynResNum)
		{
			var ascent = Graphics.getFontAscent(dynResResource[i]);
			var descent = Graphics.getFontDescent(dynResResource[i]);

			// limit the size of system number fonts (as they can be way off compared to real number sizes)
			if (dynResList[i]>=Graphics.FONT_SYSTEM_NUMBER_MILD && dynResList[i]<=Graphics.FONT_SYSTEM_NUMBER_THAI_HOT)
			{
				if (ascent>systemNumberMaxAscent)
				{
					ascent = systemNumberMaxAscent;
				}

				if (descent>0)
				{
					descent = 0;
				}
			}

			val = updateFieldMaxAscentDescent(val, ascent, descent);
		}
		
		return val;
	}

	function updateFieldMaxAscentDescent(val, ascent, descent)
	{
		var a = (val&0xFF);
		var d = ((val&0xFF00) >> 8);
		
		a = getMinMax(ascent, a, displaySize);	// max ascent
		d = getMinMax(descent, d, displaySize);	// max descent
					
		return ((a&0xFF) | ((d&0xFF) << 8));
	}

    function isDynamicResourceSystemFont(i)
    {
    	return ((i<dynResNum) && (dynResList[i]<=Graphics.FONT_SYSTEM_NUMBER_THAI_HOT));
    }

	function gfxScalePositionSize(index, origSize)
	{
		// adjust sizes so they convert backwards & forwards to be the same (by adding 0.5)
		if (origSize!=displaySize) 
		{
			gfxData[index] = (gfxData[index]*displaySize + origSize/2)/origSize;
		}		
	}

	var dynResSizeArray = new[95]b;
	var dynResOuterSizeArray = new[25/*SECONDFONT_UNUSED*/]b;

	function gfxAddDynamicResources(fontIndex)
	{	
    	var fonts = Rez.Fonts;
    	var jsonData = Rez.JsonData;
		var graphics = Graphics;

		// size rounded up in 50 byte blocks
		// also see System.getSystemStats().freeMemory
		// Total free mem = 34416 (=688*50) - then subtract about 4k for peak overhead 
//		var sizeArray240 = [
//			0, 0, 0, 0, 0,				// system
//			0, 0, 0, 0,					// system number
//			37, 41, 48, 54, 52, 50,		// big s
//			42, 51, 60, 60, 60, 58,		// big m
//			46, 58, 66, 66, 66, 64,		// big l
//			10, 12, 14,					// big colons
//			12, 14, 14, 15, 15,			// num s
//			14, 16, 19, 18, 20,			// num m
//			19, 21, 22, 23, 23,			// num l
//			27, 32, 32, 35, 33,			// abc s
//			32, 37, 44, 42, 46,			// abc m
//			45, 53, 55, 56, 56,			// abc l
//			45,							// icon
//			48, 41, 49, 40, 43, 39, 35, 31, 49, 48, 40, 40, 50		// ring (+328 bytes (7) for position array)
//		]b;

		var fontList = [
		// 0
			graphics.FONT_SYSTEM_XTINY, 			// APPFONT_SYSTEM_XTINY
			graphics.FONT_SYSTEM_TINY, 				// APPFONT_SYSTEM_TINY
			graphics.FONT_SYSTEM_SMALL, 			// APPFONT_SYSTEM_SMALL
			graphics.FONT_SYSTEM_MEDIUM,			// APPFONT_SYSTEM_MEDIUM
			graphics.FONT_SYSTEM_LARGE,				// APPFONT_SYSTEM_LARGE
			
		// 5
			graphics.FONT_SYSTEM_NUMBER_MILD,		// APPFONT_SYSTEM_NUMBER_NORMAL 
			graphics.FONT_SYSTEM_NUMBER_MEDIUM,		// APPFONT_SYSTEM_NUMBER_MEDIUM 
			graphics.FONT_SYSTEM_NUMBER_HOT,		// APPFONT_SYSTEM_NUMBER_LARGE 
			graphics.FONT_SYSTEM_NUMBER_THAI_HOT,	// APPFONT_SYSTEM_NUMBER_HUGE 

		// 9
			fonts.id_half_1,		// half font (ultra light)
			fonts.id_half_2,		// half font (extra light)
			fonts.id_half_3,		// half font (light)
			fonts.id_half_4,		// half font (regular)
			fonts.id_half_5,		// half font (bold)
		// 14
			fonts.id_half_italic_1,		// half font (ultra light)
			fonts.id_half_italic_2,		// half font (extra light)
			fonts.id_half_italic_3,		// half font (light)
			fonts.id_half_italic_4,		// half font (regular)
			fonts.id_half_italic_5,		// half font (bold)

		// 19
			fonts.id_large_s_1,		// large font minus (ultra light)
			fonts.id_large_s_2,		// large font minus (extra light)
			fonts.id_large_s_3,		// large font minus (light)
			fonts.id_large_s_4,		// large font minus (regular)
			fonts.id_large_s_5,		// large font minus (bold)
			fonts.id_large_s_6,		// large font minus (heavy)
		// 25
			fonts.id_large_italic_s_1,		// large font minus (ultra light)
			fonts.id_large_italic_s_2,		// large font minus (extra light)
			fonts.id_large_italic_s_3,		// large font minus (light)
			fonts.id_large_italic_s_4,		// large font minus (regular)
			fonts.id_large_italic_s_5,		// large font minus (bold)
			fonts.id_large_italic_s_6,		// large font minus (heavy)

		// 31
			fonts.id_large_m_1,		// large font (ultra light)
			fonts.id_large_m_2,		// large font (extra light)
			fonts.id_large_m_3,		// large font (light)
			fonts.id_large_m_4,		// large font (regular)
			fonts.id_large_m_5,		// large font (bold)
			fonts.id_large_m_6,		// large font (heavy)
		// 37
			fonts.id_large_italic_m_1,		// large font (ultra light)
			fonts.id_large_italic_m_2,		// large font (extra light)
			fonts.id_large_italic_m_3,		// large font (light)
			fonts.id_large_italic_m_4,		// large font (regular)
			fonts.id_large_italic_m_5,		// large font (bold)
			fonts.id_large_italic_m_6,		// large font (heavy)

		// 43
			fonts.id_large_l_1,		// large font plus (ultra light)
			fonts.id_large_l_2,		// large font plus (extra light)
			fonts.id_large_l_3,		// large font plus (light)
			fonts.id_large_l_4,		// large font plus (regular)
			fonts.id_large_l_5,		// large font plus (bold)
			fonts.id_large_l_6,		// large font plus (heavy)
		// 49
			fonts.id_large_italic_l_1,		// large font plus (ultra light)
			fonts.id_large_italic_l_2,		// large font plus (extra light)
			fonts.id_large_italic_l_3,		// large font plus (light)
			fonts.id_large_italic_l_4,		// large font plus (regular)
			fonts.id_large_italic_l_5,		// large font plus (bold)
			fonts.id_large_italic_l_6,		// large font plus (heavy)

		// 55
			fonts.id_colon_half,		// colon half font
			fonts.id_colon_half_italic,	// colon half font
		// 57
			fonts.id_colon_s,			// colon font minus
			fonts.id_colon_italic_s,	// colon font minus
			fonts.id_colon_m,			// colon font
			fonts.id_colon_italic_m,	// colon font
			fonts.id_colon_l,			// colon font plus
			fonts.id_colon_italic_l,	// colon font plus
			
		// 63
			fonts.id_num_s_1,		// number font minus (extra light)
			fonts.id_num_s_2,		// number font minus (light)
			fonts.id_num_s_3,		// number font minus (regular)
			fonts.id_num_s_4,		// number font minus (bold)
			fonts.id_num_s_5,		// number font minus (heavy)

			fonts.id_num_m_1,		// number font (extra light)
			fonts.id_num_m_2,		// number font (light)
			fonts.id_num_m_3,		// number font (regular)
			fonts.id_num_m_4,		// number font (bold)
			fonts.id_num_m_5,		// number font (heavy)

			fonts.id_num_l_1,		// number font plus (extra light)
			fonts.id_num_l_2,		// number font plus (light)
			fonts.id_num_l_3,		// number font plus (regular)
			fonts.id_num_l_4,		// number font plus (bold)
			fonts.id_num_l_5,		// number font plus (heavy)

		// 78
			fonts.id_abc_s_1,		// alphabet font minus (extra light)
			fonts.id_abc_s_2,		// alphabet font minus (light)
			fonts.id_abc_s_3,		// alphabet font minus (regular)
			fonts.id_abc_s_4,		// alphabet font minus (bold)
			fonts.id_abc_s_5,		// alphabet font minus (heavy)

			fonts.id_abc_m_1,		// alphabet font (extra light)
			fonts.id_abc_m_2,		// alphabet font (light)
			fonts.id_abc_m_3,		// alphabet font (regular)
			fonts.id_abc_m_4,		// alphabet font (bold)
			fonts.id_abc_m_5,		// alphabet font (heavy)

			fonts.id_abc_l_1,		// alphabet font plus (extra light)
			fonts.id_abc_l_2,		// alphabet font plus (light)
			fonts.id_abc_l_3,		// alphabet font plus (regular)
			fonts.id_abc_l_4,		// alphabet font plus (bold)
			fonts.id_abc_l_5,		// alphabet font plus (heavy)

		// 93
			fonts.id_icons,
			fonts.id_icons2,
		];
		
		if (fontIndex>=0)
		{
			return addDynamicResource(fontList[fontIndex], dynResSizeArray[fontIndex]);
		}
		
		var outerList = [
			fonts.id_seconds_tri,			// SECONDFONT_TRI
			jsonData.id_secondArray,
			
			fonts.id_seconds_tri_in,		// SECONDFONT_TRI_IN
			jsonData.id_secondInArray,
			
			fonts.id_seconds_v,				// SECONDFONT_V
			jsonData.id_secondArray,
			
			fonts.id_seconds_v_in,			// SECONDFONT_V_IN
			jsonData.id_secondInArray,
			
			fonts.id_seconds_line,			// SECONDFONT_LINE
			jsonData.id_secondArray,
			
			fonts.id_seconds_linethin,		// SECONDFONT_LINETHIN
			jsonData.id_secondArray,
			
			fonts.id_seconds_circular,		// SECONDFONT_CIRCULAR
			jsonData.id_secondCircularArray,			
			fonts.id_seconds_circular_a,
			jsonData.id_secondCircularAArray,
			fonts.id_seconds_circular_b,
			jsonData.id_secondCircularBArray,
			fonts.id_seconds_circular_c,
			jsonData.id_secondCircularCArray,
			
			fonts.id_seconds_circular_wide,
			jsonData.id_secondArrayWide,
			
			fonts.id_ring_circular,
			jsonData.id_ringCircularArray,
			fonts.id_ring_circular_a,
			jsonData.id_ringCircularAArray,
			fonts.id_ring_circular_b,
			jsonData.id_ringCircularBArray,
			fonts.id_ring_circular_c,
			jsonData.id_ringCircularCArray,

			fonts.id_ring_circular_wide,
			jsonData.id_ringWideArray,
			fonts.id_ring_circular_wide_a,
			jsonData.id_ringWideAArray,

			fonts.id_ring_slashclock,
			jsonData.id_ringWideArray,
			fonts.id_ring_slashclock_a,
			jsonData.id_ringWideAArray,
			fonts.id_ring_slashanti,
			jsonData.id_ringWideArray,
			fonts.id_ring_slashanti_a,
			jsonData.id_ringWideAArray,

			fonts.id_ring_triclock,
			jsonData.id_ringWideArray,
			fonts.id_ring_triclock_a,
			jsonData.id_ringWideAArray,
			fonts.id_ring_trianti,
			jsonData.id_ringWideArray,
			fonts.id_ring_trianti_a,
			jsonData.id_ringWideAArray,
		];
		
		var origSize = 240;
		
		dynResMem50 = 0;
		dynResMemFailed = false;
    	
		if (gfxNum>0 && getGfxId(0)==0)		// header - calculate values from this here so similar to gfxOnUpdate
		{
			origSize = getMinMax(gfxData[0+2], 218, 280);	// displaysize stored in gfx
			gfxData[0+2] = displaySize;	// everything will be updated to match the real displaysize of this watch

			gfxData[0+3] = getMinMax(gfxData[0+3], 2/*COLOR_SAVE*/, 63+2/*COLOR_SAVE*/);	// propBackgroundColor
			gfxData[0+4] = getMinMax(gfxData[0+4], 2/*COLOR_SAVE*/, 63+2/*COLOR_SAVE*/);	// propForegroundColor
			//gfxData[0+5] = getMinMax(gfxData[0+5], COLOR_FOREGROUND+2/*COLOR_SAVE*/, 63+2/*COLOR_SAVE*/);	// propMenuColor editor only
			//gfxData[0+6] = getMinMax(gfxData[0+6], COLOR_NOTSET+2/*COLOR_SAVE*/, 63+2/*COLOR_SAVE*/);	// propMenuBorder editor only
			//gfxData[0+7] = getMinMax(gfxData[0+7], COLOR_NOTSET+2/*COLOR_SAVE*/, 63+2/*COLOR_SAVE*/);	// propFieldHighlight editor only
			//gfxData[0+8] = getMinMax(gfxData[0+8], COLOR_NOTSET+2/*COLOR_SAVE*/, 63+2/*COLOR_SAVE*/);	// propElementHighlight editor only
			//gfxData[0+9] = getMinMax(gfxData[0+9], 0, 1);		// propKerningOn
			gfxData[0+10] = getMinMax(gfxData[0+10], 0, 100);		// propBatteryHighPercentage, 0 to 100
			gfxData[0+11] = getMinMax(gfxData[0+11], 0, 100);		// propBatteryLowPercentage, 0 to 100
			gfxData[0+12] = getMinMax(gfxData[0+12], 0, 48);		// prop2ndTimeZoneOffset, 24==0 (0 to 48)
			gfxData[0+13] = getMinMax(gfxData[0+13], 1, 5);			// propMoveBarAlertTriggerLevel, 1 to 5
			gfxData[0+14] = getMinMax(gfxData[0+14], 0, 2); 		// propFieldFontSystemCase, (0=any, 1=upper, 2=lower)
			gfxData[0+15] = getMinMax(gfxData[0+15], 0, 4);			// propFieldFontUnsupported, (0=xtiny to 4=large)
		}

		for (var index=0; index<gfxNum; )
		{
			//var id = getGfxId(index);
			var id = (gfxData[index] & 0xFF);	// cheaper with no function call in loop
			
			switch(id)
			{
				//case 0:		// header done above
				//{
				//	break;
				//}
				
				case 1:		// field
				{
					gfxScalePositionSize(index+1, origSize);	// x from left
					gfxScalePositionSize(index+2, origSize);	// y from bottom
					break;
				}
				
				case 2:		// large (hour, minute, colon)
				{
					var r = (gfxData[index+2/*large_font*/] & 0xFF);
				 	if (r<0 || r>49)	// 0-9 (half fonts), 10-45 (s,m,l fonts), 46-49 (4 system number fonts)
				 	{
				 		r = 25/*m regular*/;
				 	}
				 	
				 	var fontListIndex;
				 	if (r<46)	// custom font
				 	{
				 		if (gfxData[index+1/*large_type*/]==2)		// colon
				 		{
				 			fontListIndex = (r<10) ? (r/5 + 55) : ((r-10)/6 + 57);
				 		}
				 		else
				 		{
				 			fontListIndex = (r+9);
				 		}
				 	}
				 	else		// system font
				 	{
				 		fontListIndex = (r-46+5);
				 	}
				 	var resourceIndex = addDynamicResource(fontList[fontListIndex], dynResSizeArray[fontListIndex]);
					gfxData[index+2/*large_font*/] = r | ((resourceIndex & 0xFF) << 16);

					break;
				}

				case 3:		// string
				{
					var r = (gfxData[index+2/*string_font*/] & 0xFF);
				 	if (r<0 || r>19)	// 0-14 (s,m,l fonts), 15-19 (5 system fonts)
				 	{
				 		r = 7/*m regular*/;
				 	}
				 	var useNumFont = ((gfxData[index+1]&0x80)==0);
				 	var fontListIndex = ((r<15) ? (r + (useNumFont?63:78)) : (r-15+0));
					var resourceIndex = addDynamicResource(fontList[fontListIndex], dynResSizeArray[fontListIndex]);
					gfxData[index+2/*string_font*/] = r | ((resourceIndex & 0xFF) << 16);

					break;
				}
				
				case 4:		// icon
				case 5:		// movebar
				{
					var r = (gfxData[index+2/*icon_font*/] & 0xFF);
				 	if (r<0 || r>1)
				 	{
				 		r = 0;
				 	}
				 	var fontListIndex = r + 93;
					var resourceIndex = addDynamicResource(fontList[fontListIndex], dynResSizeArray[fontListIndex]);
					
					gfxData[index+2/*icon_font*/] = r | ((resourceIndex & 0xFF) << 16);

					break;
				}
				
//				case 5:		// movebar
//				{
//					var r = (gfxData[index+2/*movebar_font*/] & 0xFF);
//				 	if (r<0 || r>1)
//				 	{
//				 		r = 0;
//				 	}
//				 	var fontListIndex = r + 93;
//					var resourceIndex = addDynamicResource(fontList[fontListIndex], dynResSizeArray[fontListIndex]);
//					
//					gfxData[index+2/*movebar_font*/] = r | ((resourceIndex & 0xFF) << 16);
//
//					break;
//				}
				
//				case 6:		// chart
//				{
//					break;
//				}
				
				case 7:		// rectangle
				{
					gfxScalePositionSize(index+4/*rect_x*/, origSize);	// x from left
					gfxScalePositionSize(index+5/*rect_y*/, origSize);	// y from bottom
					gfxScalePositionSize(index+6/*rect_w*/, origSize);	// width
					gfxScalePositionSize(index+7/*rect_h*/, origSize);	// height
					break;
				}
				
				case 8:	// ring
				{
					var r = (gfxData[index+2/*ring_font*/] & 0x00FF);	// font
				 	if (r<0 || r>=25/*SECONDFONT_UNUSED*/)
				 	{
				 		r = 11/*SECONDFONT_OUTER*/;
				 	}

				 	var outerListIndex = r*2;
					var resourceIndex = addDynamicResource(outerList[outerListIndex], dynResOuterSizeArray[r]);
					gfxData[index+2/*ring_font*/] = r | ((resourceIndex & 0xFF) << 16);
					
					gfxData[index+9] = addDynamicResource(outerList[outerListIndex+1], 7);

					//printRingArray(2);	// 218 ring
					//printRingFont(2, 8);
					//printRingArray(8);	// 218 ring a
					//printRingFont(8, 8);
					//printRingArray(14);	// 218 ring b
					//printRingFont(14, 8);
					//printRingArray(20);	// 218 ring c
					//printRingFont(20, 8);
					//printRingArray(6);	// 218 wide
					//printRingFont(6, 8);
					//printRingArray(16);	// 218 wide a
					//printRingFont(16, 8);

					//printRingArray(2);	// 240 ring
					//printRingFont(2, 8);
					//printRingArray(9);	// 240 ring a
					//printRingFont(9, 8);
					//printRingArray(16);	// 240 ring b
					//printRingFont(16, 8);
					//printRingArray(23);	// 240 ring c
					//printRingFont(23, 8);
					//printRingArray(7);	// 240 wide
					//printRingFont(7, 8);
					//printRingArray(19);	// 240 wide a
					//printRingFont(19, 8);

					//printRingArray(2);	// 260 ring
					//printRingFont(2, 8);
					//printRingArray(9);	// 260 ring a
					//printRingFont(9, 8);
					//printRingArray(16);	// 260 ring b
					//printRingFont(16, 8);
					//printRingArray(23);	// 260 ring c
					//printRingFont(23, 8);
					//printRingArray(7);	// 260 wide
					//printRingFont(7, 9);
					//printRingArray(19);	// 260 wide a
					//printRingFont(19, 9);

					//printRingArray(3);	// 280 ring
					//printRingFont(3, 8);
					//printRingArray(11);	// 280 ring a
					//printRingFont(11, 8);
					//printRingArray(19);	// 280 ring b
					//printRingFont(19, 8);
					//printRingArray(27);	// 280 ring c
					//printRingFont(27, 8);
					//printRingArray(8);	// 280 wide
					//printRingFont(8, 10);
					//printRingArray(22);	// 280 wide a
					//printRingFont(22, 9);

					break;
				}
				
				case 9:	// seconds
				{
					buildSecondsColorArray(index);
					
					var r = (gfxData[index+1] & 0x00FF);	// font
				 	if (r<0 || r>=25/*SECONDFONT_UNUSED*/)
				 	{
				 		r = 0/*SECONDFONT_TRI*/;
				 	}
				 	
				 	var outerListIndex = r*2;
					propSecondResourceIndex = addDynamicResource(outerList[outerListIndex], dynResOuterSizeArray[r]);
					propSecondPositionsIndex = addDynamicResource(outerList[outerListIndex+1], 7);
					
			    	propSecondRefreshStyle = ((gfxData[index+1] >> 8) & 0xFF);	// refresh style
			    	if (propSecondRefreshStyle!=1/*REFRESH_EVERY_MINUTE*/)
			    	{
						propSecondBufferIndex = addDynamicResource(BUFFER_RESOURCE, 84);
					}
					
					//printSecondArray(6);	// 218 tri
					//printSecondFont(6, 8);
					//printSecondArray(11);	// 218 move in
					//printSecondFont(11, 8);
					//printSecondArray(2);	// 218 circular
					//printSecondFont(2, 8);
					//printSecondArray(8);	// 218 circular a
					//printSecondFont(8, 8);
					//printSecondArray(14);	// 218 circular b
					//printSecondFont(14, 8);
					//printSecondArray(20);	// 218 circular c
					//printSecondFont(20, 8);
					//printSecondArray(6);	// 218 wide
					//printSecondFont(6, 8);

					//printSecondArray(8);	// 240 tri
					//printSecondFont(8, 8);
					//printSecondArray(12);	// 240 move in
					//printSecondFont(12, 8);
					//printSecondArray(2);	// 240 circular
					//printSecondFont(2, 8);
					//printSecondArray(9);	// 240 circular a
					//printSecondFont(9, 8);
					//printSecondArray(16);	// 240 circular b
					//printSecondFont(16, 8);
					//printSecondArray(23);	// 240 circular c
					//printSecondFont(23, 8);
					//printSecondArray(7);	// 240 wide
					//printSecondFont(7, 8);

					//printSecondArray(8);	// 260 tri
					//printSecondFont(8, 8);
					//printSecondArray(12);	// 260 move in
					//printSecondFont(12, 8);
					//printSecondArray(2);	// 260 circular
					//printSecondFont(2, 8);
					//printSecondArray(9);	// 260 circular a
					//printSecondFont(9, 8);
					//printSecondArray(16);	// 260 circular b
					//printSecondFont(16, 8);
					//printSecondArray(23);	// 260 circular c
					//printSecondFont(23, 8);
					//printSecondArray(7);	// 260 wide
					//printSecondFont(7, 9);

					//printSecondArray(9);	// 280 tri
					//printSecondFont(9, 8);
					//printSecondArray(13);	// 280 move in
					//printSecondFont(13, 8);
					//printSecondArray(3);	// 280 circular
					//printSecondFont(3, 8);
					//printSecondArray(11);	// 280 circular a
					//printSecondFont(11, 8);
					//printSecondArray(19);	// 280 circular b
					//printSecondFont(19, 8);
					//printSecondArray(27);	// 280 circular c
					//printSecondFont(27, 8);
					//printSecondArray(8);	// 280 wide
					//printSecondFont(8, 10);

					break;
				}
			}
						
			//index += gfxSize(id);
			if (id<0 || id>=10/*GFX_SIZE_NUM*/)
			{
				break;
			}
			index += gfxSizeArray[id*2]; 	// cheaper with no function call in loop
		}
		
		return null;
	}
	
//	function getOuterX(r, index)
//	{
//		return (r[index] & 0xFFFF);
//	}
//	
//	function getOuterY(r, index)
//	{
//		return ((r[index]>>16) & 0xFFFF);
//	}
//	
//	function getOuterSizeHalf(r)
//	{
//		return r[61];
//	}
	
	function outerAlignedToSeconds(r)
	{
		return r[60];
	}
	
//	function calculateRingPositions(moveIn)
//	{
//		var posXY = new[2];
//		posXY[0] = new[60];
//		posXY[1] = new[60];
//
//		var offset = displayHalf - moveIn;
//
//		for (var i=0; i<60; i++)
//		{
//	        var r = Math.toRadians((i*6) + 3.0);	// to centre of arc
//
//        	// centre of char
//	    	posXY[0][i] = getMax(Math.floor(displayHalf + offset*Math.sin(r) + 0.5), 0);
//	    	posXY[1][i] = getMax(Math.floor(displayHalf - offset*Math.cos(r) + 0.5), 0);
//		}
//		
//		return posXY;
//	}
//	
//	function printRingArray(moveIn)
//	{
//		var posXY = calculateRingPositions(moveIn);
//	
//		var posArray = new[60];
//
//		for (var i=0; i<60; i++)
//		{
//			var xCentre = posXY[0][i].toNumber();
//	    	var yCentre = posXY[1][i].toNumber();
//	    	posArray[i] = (xCentre & 0xFFFF) | ((yCentre & 0x8FFFF)<<16); 
//		}
//
//		System.println(posArray);
//	}
//
//	function printRingFont(moveIn, sizeHalf)
//	{
//		var posXY = calculateRingPositions(moveIn);
//	
//		// debug code for calculating font character positions
//        for (var i = 0; i < 60; i++)
//        {
//    		var id = 21/*OUTER_FIRST_CHAR_ID*/ + i;
//			var page = (i % 2);		// even or odd pages
//			var x = posXY[0][i].toNumber() - sizeHalf;	// top left
//        	var y = posXY[1][i].toNumber() - sizeHalf;	// top left
//
//        	var s = Lang.format("char id=$1$ x=$2$ y=$3$ width=$4$ height=$4$ xoffset=0 yoffset=0 xadvance=$4$ page=$5$ chnl=15", [id, x.format("%d"), y.format("%d"), sizeHalf*2, page]);
//        	System.println(s);
//		}
//	}

//	function calculateSecondPositions(moveIn)
//	{
//		var posXY = new[2];
//		posXY[0] = new[60];
//		posXY[1] = new[60];
//
//		var offset = displayHalf - moveIn;
//
//		for (var i=0; i<60; i++)
//		{
//	        var r = Math.toRadians(i*6);
//
//        	// centre of char
//	    	posXY[0][i] = getMax(Math.floor(displayHalf + offset*Math.sin(r) + 0.5), 0);
//	    	posXY[1][i] = getMax(Math.floor(displayHalf - offset*Math.cos(r) + 0.5), 0);
//		}
//		
//		return posXY;
//	}
//
//	function printSecondArray(moveIn)
//	{
//		var posXY = calculateSecondPositions(moveIn);
//	
//		var posArray = new[60];
//
//		for (var i=0; i<60; i++)
//		{
//			var xCentre = posXY[0][i].toNumber();
//	    	var yCentre = posXY[1][i].toNumber();
//	    	posArray[i] = (xCentre & 0xFFFF) | ((yCentre & 0x8FFFF)<<16); 
//		}
//
//		System.println(posArray);
//	}
//
//	function printSecondFont(moveIn, sizeHalf)
//	{
//		var posXY = calculateSecondPositions(moveIn);
//	
//		// debug code for calculating font character positions
//        for (var i = 0; i < 60; i++)
//        {
//			var id = 21/*SECONDS_FIRST_CHAR_ID*/ + i;
//			var page = (i % 2);		// even or odd pages
//			var x = posXY[0][i].toNumber() - sizeHalf;	// top left
//        	var y = posXY[1][i].toNumber() - sizeHalf;	// top left
//
//        	var s = Lang.format("char id=$1$ x=$2$ y=$3$ width=$4$ height=$4$ xoffset=0 yoffset=0 xadvance=$4$ page=$5$ chnl=15", [id, x.format("%d"), y.format("%d"), sizeHalf*2, page]);
//        	System.println(s);
//		}
//	}

	function buildSecondsColorArray(index)
	{
		// calculate the seconds color array
    	var secondColorIndex = gfxData[index+2];		// second color
    	var secondColorIndex5 = gfxData[index+3];
    	var secondColorIndex10 = gfxData[index+4];
    	var secondColorIndex15 = gfxData[index+5];
    	var secondColorIndex0 = gfxData[index+6];
    	
    	for (var i=0; i<60; i++)
    	{
			var col;
	
			if (secondColorIndex0!=(COLOR_NOTSET+2/*COLOR_SAVE*/) && i==0)
			{
				col = secondColorIndex0;
			}
			else if (secondColorIndex15!=(COLOR_NOTSET+2/*COLOR_SAVE*/) && (i%15)==0)
			{
				col = secondColorIndex15;
			}
			else if (secondColorIndex10!=(COLOR_NOTSET+2/*COLOR_SAVE*/) && (i%10)==0)
			{
				col = secondColorIndex10;
			}
			else if (secondColorIndex5!=(COLOR_NOTSET+2/*COLOR_SAVE*/) && (i%10)==5)
			{
				col = secondColorIndex5;
			}
	        else
	        {
	        	col = secondColorIndex;		// second color
	        }
	        
	        propSecondColorIndexArray[i] = col;
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
		//	propSecondColorIndexArray[i] = colArray[testArray.indexOf(true)+1];
		//}		
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

		if (gfxNum>0 && getGfxId(0)==0)		// header - calculate values from this here as they are used early ...
		{
			propBackgroundColor = getColor64FromGfx(gfxData[0+3]);
			propForegroundColor = getColor64FromGfx(gfxData[0+4]);
			//propMenuColor = getColor64FromGfx(gfxData[0+5]);			editor only
			//propMenuBorder = getColor64FromGfx(gfxData[0+6]);			editor only
			//propFieldHighlight = getColor64FromGfx(gfxData[0+7]);		editor only
			//propElementHighlight = getColor64FromGfx(gfxData[0+8]);	editor only
			propKerningOn = (gfxData[0+9]!=0);
			propBatteryHighPercentage = gfxData[0+10];		// 0 to 100
			propBatteryLowPercentage = gfxData[0+11];		// 0 to 100
			prop2ndTimeZoneOffset = gfxData[0+12] - 24;		// 24==0 (0 to 48)
			propMoveBarAlertTriggerLevel = gfxData[0+13];	// 1 to 5
			propFieldFontSystemCase = gfxData[0+14]; 		// (0=any, 1=upper, 2=lower)
			propFieldFontUnsupported = gfxData[0+15];		// (0=xtiny to 4=large)
		}

        var deviceSettings = System.getDeviceSettings();		// 960 bytes, but uses less code memory
		var activityMonitorInfo = ActivityMonitor.getInfo();  	// 560 bytes, but uses less code memory
		var systemStats = System.getSystemStats();				// 168 bytes, but uses less code memory
        var firstDayOfWeek = deviceSettings.firstDayOfWeek;
		var gregorian = Time.Gregorian;
		var dateInfoShort = gregorian.info(timeNow, Time.FORMAT_SHORT);
		var dateInfoMedium = gregorian.info(timeNow, Time.FORMAT_MEDIUM);
		var dayNumberOfWeek = (((dateInfoShort.day_of_week - firstDayOfWeek + 7) % 7) + 1);		// 1-7
		var hour2nd = (hour - clockTime.timeZoneOffset/3600 + prop2ndTimeZoneOffset + 48)%24;		// 2nd time zone

		// calculate fields to display
		var visibilityStatus = new[25/*STATUS_NUM*/];
		visibilityStatus[0/*STATUS_ALWAYSON*/] = true;
	    visibilityStatus[1/*STATUS_GLANCE_ON*/] = glanceActive;
	    visibilityStatus[2/*STATUS_GLANCE_OFF*/] = !glanceActive;
	    visibilityStatus[3/*STATUS_DONOTDISTURB_ON*/] = (hasDoNotDisturb && deviceSettings.doNotDisturb);
	    visibilityStatus[4/*STATUS_DONOTDISTURB_OFF*/] = (hasDoNotDisturb && !deviceSettings.doNotDisturb);
	    var alarmCount = deviceSettings.alarmCount;
	    visibilityStatus[5/*STATUS_ALARM_ON*/] = (alarmCount > 0);
	    visibilityStatus[6/*STATUS_ALARM_OFF*/] = (alarmCount == 0);
	    var notificationCount = deviceSettings.notificationCount;
	    visibilityStatus[7/*STATUS_NOTIFICATIONS_PENDING*/] = (notificationCount > 0);
	    visibilityStatus[8/*STATUS_NOTIFICATIONS_NONE*/] = (notificationCount == 0);
	    var phoneConnected = deviceSettings.phoneConnected;
	    visibilityStatus[9/*STATUS_PHONE_CONNECTED*/] = phoneConnected;
	    visibilityStatus[10/*STATUS_PHONE_NOT*/] = !phoneConnected;
	    var lteState = lteConnected();
	    visibilityStatus[11/*STATUS_LTE_CONNECTED*/] = (hasLTE && lteState);
	    visibilityStatus[12/*STATUS_LTE_NOT*/] = (hasLTE && !lteState);
	    var batteryLevel = systemStats.battery;
	    visibilityStatus[14/*STATUS_BATTERY_HIGH*/] = (batteryLevel>=propBatteryHighPercentage);
	    visibilityStatus[16/*STATUS_BATTERY_LOW*/] = (!visibilityStatus[12/*STATUS_BATTERY_HIGH*/] && batteryLevel<=propBatteryLowPercentage);
	    visibilityStatus[15/*STATUS_BATTERY_MEDIUM*/] = (!visibilityStatus[12/*STATUS_BATTERY_HIGH*/] && !visibilityStatus[14/*STATUS_BATTERY_LOW*/]);
	    visibilityStatus[13/*STATUS_BATTERY_HIGHORMEDIUM*/] = !visibilityStatus[14/*STATUS_BATTERY_LOW*/];
		// moveBarLevel 0 = not triggered
		// moveBarLevel has range 1 to 5
		// propFieldMoveAlarmTriggerTime has range 1 to 5
		var activityTrackingOn = deviceSettings.activityTrackingOn;
		var activityMonitorMoveBarLevel = getNullCheckZero(activityMonitorInfo.moveBarLevel);
	    var moveBarAlertTriggered = (activityMonitorMoveBarLevel >= propMoveBarAlertTriggerLevel); 
	    visibilityStatus[17/*STATUS_MOVEBARALERT_TRIGGERED*/] = (activityTrackingOn && moveBarAlertTriggered);
	    visibilityStatus[18/*STATUS_MOVEBARALERT_NOT*/] = (activityTrackingOn && !moveBarAlertTriggered);
	    visibilityStatus[19/*STATUS_AM*/] = (hour < 12);
	    visibilityStatus[20/*STATUS_PM*/] = (hour >= 12);
	    visibilityStatus[21/*STATUS_2ND_AM*/] = (hour2nd < 12);
	    visibilityStatus[22/*STATUS_2ND_PM*/] = (hour2nd >= 12);
	    visibilityStatus[23/*STATUS_SUNEVENT_RISE*/] = null;	// calculated on demand
	    visibilityStatus[24/*STATUS_SUNEVENT_SET*/] = null;		// calculated on demand

		fieldActivePhoneStatus = null;
		fieldActiveNotificationsStatus = null;
		fieldActiveNotificationsCount = null;
		fieldActiveLTEStatus = null;
		
    	propSecondIndicatorOn = false;

		var indexCurField = -1;
		var fieldVisible = false;
		
//		var indexPrevLargeWidth = -1;
//		var prevLargeNumber = -1;
//		var prevLargeFontKern = -1;
	
		gfxCharArrayLen = 0;
	
		for (var index=0; index<gfxNum; )
		{
			//var id = getGfxId(index);
			var id = (gfxData[index] & 0xFF);	// cheaper with no function call in loop
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
//				case 0:		// header - handled above before visibility calculations
//				{
//					break;
//				}

				case 1:		// field
				{
        			//System.println("gfxOnUpdate field");

					indexCurField = index;
					fieldVisible = isVisible;

					gfxData[index+4] = 0;	// total width
					gfxData[index+5] = 0;	// ascent & descent
					//gfxData[index+5] = 0;	// no x adjustment yet
					
					break;
				}

				case 2:		// large (hour, minute, colon)
				{
        			//System.println("gfxOnUpdate large");
				
					if (!(fieldVisible && isVisible))
					{
						break;
					}
					
					var resourceIndex = ((gfxData[index+2/*large_font*/] >> 16) & 0xFF);
					var dynamicResource = getDynamicResource(resourceIndex);
					if (dynamicResource==null)
					{
						gfxData[index+5] = 0;	// width 0
						gfxData[index+7] = 0;	// width 0
						break;
					}
					
//					var narrowKern = false;
//
//					var fontTypeKern = (gfxData[index+1] & 0xFF);
//					if (fontTypeKern>=6)
//					{
//						if (fontTypeKern>=33 && fontTypeKern<=38)	// large italic
//						{
//							fontTypeKern -= 33;
//						}
//						else if (fontTypeKern>=39 && fontTypeKern<=56)	// large mono
//						{
//							fontTypeKern = (fontTypeKern - 39)%6;
//						}
//						else
//						{
//							fontTypeKern = -1;		// no kerning
//						}
//					}

					var charArray;
					var largeType = gfxData[index+1/*large_type*/];
					if (largeType==0)
					{
						charArray = formatHourForDisplayString(hour, deviceSettings.is24Hour, false).toCharArray();
					}
					else if (largeType==1)
					{
						charArray = minute.format("%02d").toCharArray();
					}
					else //if (largeType==2)
					{
						var r = (gfxData[index+2/*large_font*/] & 0xFF);
					 	if (r<10)	// 0-9 (half fonts), 10-45 (s,m,l fonts), 46-49 (4 system number fonts)
					 	{
							charArray = [((r%5) + 48).toChar()];
					 	}
					 	else if (r<46)
					 	{
							charArray = [(((r-10)%6) + 48).toChar()];
					 	}
					 	else
					 	{
							charArray = ":".toCharArray();
					 	}
					}
					
					var charArraySize = charArray.size();
					var charArrayIndex = 0;

					for (var j=0; j<=2; j+=2)
					{
						var indexWidthJ = index+5+j; 
					
						if (j==0 && charArraySize==1)	// if only 1 character then store it in the 2nd slot
						{
							//gfxData[index+3] = 0;	// string 0
							gfxData[indexWidthJ] = 0;	// width 0
							continue;
						}
						
						var c = charArray[charArrayIndex];
						var cNum = c.toNumber();
						charArrayIndex++;
						gfxData[indexWidthJ-1] = c;	// string 0 or 1
						gfxData[indexWidthJ] = dc.getTextWidthInPixels(c.toString(), dynamicResource);	// width 0 or 1
						gfxData[indexCurField+4] += gfxData[indexWidthJ];	// total width
						
//						if (indexPrevLargeWidth>=0 && prevLargeFontKern>=0 && fontTypeKern>=0)
//						{
//							var k = getKern(prevLargeNumber - 48/*APPCHAR_0*/, cNum - 48/*APPCHAR_0*/, prevLargeFontKern, fontTypeKern, narrowKern);
//							gfxData[indexPrevLargeWidth] -= k;
//							gfxData[indexCurField+4] -= k;	// total width
//						}
						
//						indexPrevLargeWidth = indexWidthJ;
//						prevLargeNumber = cNum;
//						prevLargeFontKern = fontTypeKern;

						// for last digit in current field (if it is large font)
//						if (j!=0)
//						{
//							gfxData[indexCurField+5] = 0;	// remove existing x adjustment
//							if (gfxData[indexCurField+3]==0)	// centre justification
//							{
//								//if (italic font)
//								//{
//								//	gfxData[indexCurField+5] += 1;	// shift right 1 pixel
//								//}
//								
//								if ((cNum - 48/*APPCHAR_0*/) == 4)		// last digit is a 4 
//								{
//									gfxData[indexCurField+5] += 1;	// shift right 1 more pixel
//								}
//							}
//						}
					}

					gfxData[indexCurField+5] = updateFieldMaxAscentDescentResource(gfxData[indexCurField+5], resourceIndex);		// store max ascent & descent in field
					
					break;
				}
				
				case 3:		// string
				{
					if (!(fieldVisible && isVisible))
					{
						break;
					}

					var resourceIndex = ((gfxData[index+2/*string_font*/] >> 16) & 0xFF);

					var eStr = null;
					var eDisplay = (gfxData[index+1] & 0x7F);	// 0x80 is for useNumFont
					var makeUpperCase = false;
					var checkDiacritics = false;
					var useUnsupportedFont = false;
					
//					if (eDisplay>=80 && eDisplay<110)
//					{
//						// time (advanced)
//					}
					
					switch(eDisplay)	// type of string
					{
						case 1/*FIELD_HOUR*/:			// hour
					    {
							eStr = formatHourForDisplayString(hour, deviceSettings.is24Hour, false);
							break;
						}
	
						case 2/*FIELD_MINUTE*/:			// minute
					    {
							eStr = minute.format("%02d");
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
							
								if (propFieldFontSystemCase==1)	// APPCASE_UPPER = 1
								{
									makeUpperCase = true;
								}
								else if (propFieldFontSystemCase==2)	// APPCASE_LOWER = 2
								{
									eStr = eStr.toLower();
								}
							}
							else
							{
								if (useUnsupportedFieldFont(eStr))
								{
									useUnsupportedFont = true;

									// will be using system font - so use case for that as specified by user
									if (propFieldFontSystemCase==1)	// APPCASE_UPPER = 1
									{
										makeUpperCase = true;
									}
									else if (propFieldFontSystemCase==2)	// APPCASE_LOWER = 2
									{
										eStr = eStr.toLower();
									}
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

						case 15/*FIELD_WEEK_ISO_W*/:		// W
						{
							eStr = "W";
							break;
						}
	
						case 14/*FIELD_WEEK_ISO_XX*/:			// week number of year XX
						case 16/*FIELD_YEAR_ISO_WEEK_XXXX*/:
						{
							calculateDayWeekYearData(1, firstDayOfWeek, dateInfoMedium);							
        					eStr = ((eDisplay==14/*FIELD_WEEK_ISO_XX*/) ? ISOWeek.format("%02d") : "" + ISOYear);
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
	
						case 21/*FIELD_A*/:
					    {
							eStr = "A";
							break;
						}
	
						case 22/*FIELD_P*/:
					    {
							eStr = "P";
							break;
						}
	
					    case 23/*FIELD_SEPARATOR_SPACE*/:
					    case 24:
					    case 25:
					    case 26/*FIELD_SEPARATOR_COLON*/:
					    case 27:
					    case 28:
					    case 29:
					    case 30/*FIELD_SEPARATOR_PERCENT*/:
					    {
							var separatorString = " /\\:-.,%";
		        			eStr = separatorString.substring(eDisplay-23/*FIELD_SEPARATOR_SPACE*/, eDisplay-23/*FIELD_SEPARATOR_SPACE*/+1);
		        			break;
					    }

						case 31/*FIELD_STEPSCOUNT*/:
						{
							eStr = "" + getNullCheckZero(activityMonitorInfo.steps);
							break;
						}

						case 32/*FIELD_STEPSGOAL*/:
						{
							eStr = "" + getNullCheckZero(activityMonitorInfo.stepGoal);
							break;
						}

						case 33/*FIELD_FLOORSCOUNT*/:
						{
							eStr = "" + (hasFloorsClimbed ? getNullCheckZero(activityMonitorInfo.floorsClimbed) : 0);
							break;
						}

						case 34/*FIELD_FLOORSGOAL*/:
						{
							eStr = "" + (hasFloorsClimbed ? getNullCheckZero(activityMonitorInfo.floorsClimbedGoal) : 0);
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
						
						case 37/*FIELD_HEART_MIN*/:
						case 38/*FIELD_HEART_MAX*/:
						case 39/*FIELD_HEART_AVERAGE*/:
						case 40/*FIELD_HEART_LATEST*/:
						{
							calculateHeartRate(minute, second);

							var heartVal = (eDisplay==40/*FIELD_HEART_LATEST*/) ? heartDisplayLatest : 
										((eDisplay==37/*FIELD_HEART_MIN*/) ? heartDisplayMin : ((eDisplay==38/*FIELD_HEART_MAX*/) ? heartDisplayMax : heartDisplayAverage));
							eStr = (heartVal!=null) ? heartVal.format("%d") : "--";
							break;
						}

						case 41/*FIELD_SUNRISE_HOUR*/:
						case 42/*FIELD_SUNRISE_MINUTE*/:
						case 43/*FIELD_SUNSET_HOUR*/:
						case 44/*FIELD_SUNSET_MINUTE*/:
						case 45/*FIELD_SUNEVENT_HOUR*/:
						case 46/*FIELD_SUNEVENT_MINUTE*/:
						{
							calculateSun(dateInfoShort);

							var t = null;
							if (eDisplay>=45/*FIELD_SUNEVENT_HOUR*/)	// next sun event?
							{
								t = sunTimes[6];	// null or time of next sun event
							}
							else
							{
								// sunrise or sunset today
								t = ((eDisplay<=42/*FIELD_SUNRISE_MINUTE*/) ? sunTimes[0] : sunTimes[1]);
							}
																	
							if (t!=null)
							{
								t += 24*60;		// add 24 hours to make sure it is a positive number (if sunrise was before midnight ...) 
								if ((eDisplay-41/*FIELD_SUNRISE_HOUR*/)%2==1)
								{
									eStr = (t%60).format("%02d");		// minutes
								}
								else
								{
									eStr = formatHourForDisplayString((t/60)%24, deviceSettings.is24Hour, false);	// hours
								}
							}
							else
							{
								eStr = "--";
							}
							
							break;
						}

						case 47/*FIELD_2ND_HOUR*/:
						{
							eStr = formatHourForDisplayString(hour2nd, deviceSettings.is24Hour, false);	// hours
							break;
						}

						case 48/*FIELD_CALORIES*/:
						{
							eStr = "" + getNullCheckZero(activityMonitorInfo.calories);
							break;
						}

						case 49/*FIELD_ACTIVE_CALORIES*/:
						case 61/*FIELD_RESTING_CALORIES*/:
						{
							var userProfile = UserProfile.getProfile();
							//var nonActiveCalories = 1.2*((10.0/1000.0)*userProfile.weight + 6.25*userProfile.height - 5.0*(dateInfoMedium.year-userProfile.birthYear) + ((userProfile.gender==1/*GENDER_MALE*/)?5:(-161)));
							var nonActiveCalories = (12.2/1000.0)*userProfile.weight + 7.628*userProfile.height - 6.116*(dateInfoMedium.year-userProfile.birthYear) + ((userProfile.gender==1/*GENDER_MALE*/)?5.2:(-197.6));
							nonActiveCalories = ((nonActiveCalories * timeNowInMinutesToday) / (24*60) + 0.5).toNumber(); 
							var val = ((eDisplay==49/*FIELD_ACTIVE_CALORIES*/) ? (getNullCheckZero(activityMonitorInfo.calories) - nonActiveCalories) : nonActiveCalories);
							eStr = "" + ((val<0) ? "0" : val);
							break;
						}

						case 50/*FIELD_INTENSITY*/:
						{
							eStr = "" + ((activityMonitorInfo.activeMinutesWeek!=null) ? activityMonitorInfo.activeMinutesWeek.total : 0);
							break;
						}

						case 51/*FIELD_INTENSITY_GOAL*/:
						{
							eStr = "" + getNullCheckZero(activityMonitorInfo.activeMinutesWeekGoal);
							break;
						}

						case 52/*FIELD_SMART_GOAL*/:
						{
							eStr = "" + ((getNullCheckZero(activityMonitorInfo.activeMinutesWeekGoal) * dayNumberOfWeek) / 7);
							break;
						}

						case 53/*FIELD_DISTANCE*/:
						{
							// convert cm to miles or km
							var d = getNullCheckZero(activityMonitorInfo.distance) / ((deviceSettings.distanceUnits==System.UNIT_STATUTE) ? 160934.4 : 100000.0);
							eStr = d.format("%.1f");
							break;
						}

						case 54/*FIELD_DISTANCE_UNITS*/:
						{
							eStr = ((deviceSettings.distanceUnits==System.UNIT_STATUTE) ? "mi" : "km");
							makeUpperCase = !isDynamicResourceSystemFont(resourceIndex);
							break;
						}

						case 55/*FIELD_PRESSURE*/:
						{
							if (hasPressureHistory)
							{
								var pressureSample = SensorHistory.getPressureHistory({:period => 1}).next();
								if (pressureSample!=null && pressureSample.data!=null)
								{ 
									eStr = (pressureSample.data / 100.0).format("%d");	// convert Pa to mbar
								}
								else
								{
									eStr = "---";
								}
							}
							break;
						}

						case 56/*FIELD_PRESSURE_UNITS*/:
						{
							eStr = "mb"; 	// mbar
							makeUpperCase = !isDynamicResourceSystemFont(resourceIndex);
							break;
						}

						case 57/*FIELD_ALTITUDE*/:
						{
							// convert m to feet or m
							eStr = ((deviceSettings.elevationUnits==System.UNIT_STATUTE) ? (positionAltitude*3.2808399) : positionAltitude).format("%d");
							break;
						}

						case 58/*FIELD_ALTITUDE_UNITS*/:
						{
							eStr = ((deviceSettings.elevationUnits==System.UNIT_STATUTE) ? "ft" : "m");
							makeUpperCase = !isDynamicResourceSystemFont(resourceIndex);
							break;
						}

						case 59/*FIELD_TEMPERATURE*/:
						{
							if (hasTemperatureHistory)
							{
								var temperatureSample = SensorHistory.getTemperatureHistory({:period => 1}).next();
								if (temperatureSample!=null && temperatureSample.data!=null)
								{ 
									eStr = (Math.round((deviceSettings.temperatureUnits==System.UNIT_STATUTE) ? (temperatureSample.data*1.8 + 32) : temperatureSample.data)).format("%d");
								}
								else
								{
									eStr = "--";
								}
							}
							break;
						}
						
						case 60/*FIELD_TEMPERATURE_UNITS*/:
						{
							eStr = ((deviceSettings.temperatureUnits==System.UNIT_STATUTE) ? "F" : "C");
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
						
						if (useUnsupportedFont)
						{
							resourceIndex = gfxAddDynamicResources(0/*APPFONT_SYSTEM_XTINY*/ + propFieldFontUnsupported);
							gfxData[index+2/*string_font*/] &= ~0x00FF0000;
							gfxData[index+2/*string_font*/] |= ((resourceIndex & 0xFF) << 16);
						}

						var dynamicResource = getDynamicResource(resourceIndex);

						if (dynamicResource==null)
						{
							gfxData[index+4] = sLen;
							gfxData[index+5] = sLen;
							gfxData[index+6] = 0;
						}
						else
						{
							if (checkDiacritics)
							{
								eLen = addStringToCharArrayWithDiacritics(eStr, gfxCharArray, sLen, MAX_GFX_CHARS);
								gfxCharArrayLen = eLen + (eLen-sLen);
								eStr = StringUtil.charArrayToString(gfxCharArray.slice(sLen, eLen));	// string without diacritics
	
								gfxData[index+2/*string_font*/] |= 0x80000000;		// diacritics flag
							}
							else
							{
								eLen = addStringToCharArray(eStr, gfxCharArray, sLen, MAX_GFX_CHARS);
								gfxCharArrayLen = eLen;
	
								gfxData[index+2/*string_font*/] &= ~0x80000000;		// diacritics flag
							}
		
							gfxData[index+4] = sLen;	// string start
							gfxData[index+5] = eLen;	// string end
							gfxData[index+6] = dc.getTextWidthInPixels(eStr, dynamicResource);
							gfxData[indexCurField+4] += gfxData[index+6];	// total width
							gfxData[indexCurField+5] = updateFieldMaxAscentDescentResource(gfxData[indexCurField+5], resourceIndex);		// store max ascent & descent in field
							//gfxData[indexCurField+5] = 0;	// remove existing x adjustment
						}					
					}
					else
					{
						gfxData[index+4] = 0;	// string start
						gfxData[index+5] = 0;	// string end
						gfxData[index+6] = 0;	// width
					}
					
					break;
				}
				
				case 4:		// icon
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

						var resourceIndex = ((gfxData[index+2/*icon_font*/] >> 16) & 0xFF);
						var dynamicResource = getDynamicResource(resourceIndex);
						if (dynamicResource==null)
						{
							break;
						}

						gfxData[index+4] = c;	// char
						gfxData[index+5] = dc.getTextWidthInPixels(c.toString(), dynamicResource);
						gfxData[indexCurField+4] += gfxData[index+5];	// total width					
						gfxData[indexCurField+5] = updateFieldMaxAscentDescentResource(gfxData[indexCurField+5], resourceIndex);		// store max ascent & descent in field
						//gfxData[indexCurField+5] = 0;	// remove existing x adjustment
				    }

					break;
				}
				
				case 5:		// movebar
				{
					if (!(fieldVisible && isVisible))
					{
						break;
					}

					gfxData[index+9] = activityMonitorMoveBarLevel;	// level
					gfxData[index+10] = 0;	// width

					var resourceIndex = ((gfxData[index+2/*movebar_font*/] >> 16) & 0xFF);
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
					gfxData[indexCurField+5] = updateFieldMaxAscentDescentResource(gfxData[indexCurField+5]);		// store max ascent & descent in field
					//gfxData[indexCurField+5] = 0;	// remove existing x adjustment

					break;
				}
				
				case 6:		// chart
				{
					if (!(fieldVisible && isVisible))
					{
						break;
					}

					calculateHeartRate(minute, second);
					heartChartVisible = true;	// we know it is visible now

					var axesSide = ((gfxData[index+1]&0x01)!=0);
					//var axesBottom = ((gfxData[index+1]&0x02)!=0);

					gfxData[index+4] = (axesSide ? 55 : 51);	// width
					gfxData[indexCurField+4] += gfxData[index+4];	// total width					
					gfxData[indexCurField+5] = updateFieldMaxAscentDescent(gfxData[indexCurField+5], 21/*heartChartHeight*/, 0);		// store max ascent & descent in field
					//gfxData[indexCurField+5] = 0;	// remove existing x adjustment

					break;
				}
				
				case 7:		// rectangle
				{
					if (!isVisible)
					{
						break;
					}

					break;
				}
				
				case 8:	// ring
				{
					if (!isVisible)
					{
						break;
					}

					var arrayResource = getDynamicResource(gfxData[index+9]);					
					if (arrayResource==null)
					{
						break;
					}

					var alignedAdjust = (outerAlignedToSeconds(arrayResource) ? 0 : 1);

					var eDisplay = (gfxData[index+1] & 0x3F);
					var eDirAnti = ((gfxData[index+1] & 0x40) != 0);	// false==clockwise
					var eLimit100 = ((gfxData[index+1] & 0x80) != 0);

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

					// Other things that could be displayed:
					//
			   		// day of week
			   		// day of month
			   		// day of year
			   		// month
			   		//
			   		// notifications count
			   		// movebar
			   		// daily active calories (filled) out of total calories so far
			   		// weekly active calories compared to previous weeks
			   		// smart training performance/load
			   		//
			   		// week ISO
			   		// week calendar
			   		// pressure	870-1084mb, standard at sea level is 1013, 300 on top of Everest, normal range is 1016+-34
			   		// temperature -50 to +50 ?
				   		
					switch (eDisplay)
					{
						//case 0:		// solid color
						//{
						//	break;
						//}
					
						case 1:		// steps
						case 2:		// floors
						case 10:	// intensity
						case 11:	// smart intensity
						{
							var val;
							var goal;
							if (eDisplay==2)
							{
								val = (hasFloorsClimbed ? getNullCheckZero(activityMonitorInfo.floorsClimbed) : 0);
								goal = (hasFloorsClimbed ? getNullCheckZero(activityMonitorInfo.floorsClimbedGoal) : 0);
							}
							else if (eDisplay==9 || eDisplay==10)
							{
								val = ((activityMonitorInfo.activeMinutesWeek!=null) ? activityMonitorInfo.activeMinutesWeek.total : 0);
								goal = getNullCheckZero(activityMonitorInfo.activeMinutesWeekGoal);

								if (eDisplay==10)	// smart
								{
									goal = ((goal * dayNumberOfWeek) / 7);
								}
							}
							else
							{
								val = getNullCheckZero(activityMonitorInfo.steps);
								goal = getNullCheckZero(activityMonitorInfo.stepGoal);
							}
							
							fillEnd = ((goal>0) ? ((drawRange * val) / goal - alignedAdjust) : -1);
							
							if (fillEnd>=drawRange)
							{
								if (drawRange<60 || eLimit100)
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

				   		case 3:		// battery percentage
				   		{
							fillEnd = (systemStats.battery * drawRange).toNumber() / 100 - alignedAdjust;
							break;
				   		}
				   		
						case 4:		// minutes
						{
			    			fillEnd = (minute * drawRange)/60 - alignedAdjust;
							break;
						}
						
						case 5:		// hours
						case 6:		// 2nd time zone hours
						{
							var useHour = ((eDisplay==3) ? hour : hour2nd);  
					        if (deviceSettings.is24Hour)
					        {
				        		//backgroundOuterFillEnd = ((hour*60 + minute) * 120) / (24 * 60);
				        		fillEnd = ((useHour*60 + minute) * drawRange) / (24*60) - alignedAdjust;
					        }
					        else        	// 12 hours
					        {
				        		fillEnd = (((useHour%12)*60 + minute) * drawRange) / (12*60) - alignedAdjust;
					        }
							break;
				   		}
				   		
				   		case 7:		// sunrise & sunset now top
				   		case 8:		// sunrise & sunset midnight top
				   		case 9:		// sunrise & sunset noon top
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
				   		
				   		case 12:	// heart rate
				   		{
							calculateHeartRate(minute, second);
							if (heartDisplayLatest!=null)
							{
								fillEnd = getMinMax((heartDisplayLatest * drawRange) / heartMaxZone5, 0, drawRange) - alignedAdjust;
							}
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
					else if (fillEnd > drawRange-1)
					{
						fillEnd = drawRange-1;
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

					gfxData[index+8] = (fillStart & 0xFF) | ((fillEnd & 0xFF) << 8) | (noFill ? 0x10000 : 0);	// start fill, end fill and no fill flag

					break;
				}
				
				case 9:	// seconds
				{
			    	propSecondIndicatorOn = isVisible;

					var dynamicPositions = getDynamicResource(propSecondPositionsIndex);
					propSecondAligned = (dynamicPositions==null || outerAlignedToSeconds(dynamicPositions));
					break;
				}
			}
			
			//index += gfxSize(id);
			if (id<0 || id>=10/*GFX_SIZE_NUM*/)
			{
				break;
			}
			index += gfxSizeArray[id*2]; 	// cheaper with no function call in loop
		}
	}
	
	function gfxFieldHighlight(dc, index, x, y, w, h)
	{
	}
		
	function gfxElementHighlight(dc, index, x, y)
	{
	}
	
	function gfxDrawBackground(dc, dcX, dcY, toBuffer)
	{
		var fieldDraw = false;
		var fieldYStart = displayHalf;
		var fieldX = displayHalf;
		
		var dcWidth = dc.getWidth();
		var dcHeight = dc.getHeight();

		for (var index=0; index<gfxNum; )
		{
			//var id = getGfxId(index);
			var id = (gfxData[index] & 0xFF);	// cheaper with no function call in loop
			var isVisible = ((gfxData[index] & 0x10000) != 0);
			
			switch(id)
			{
//				case 0:		// header
//				{
//					break;
//				}
				
				case 1:		// field
				{
        			//System.println("gfxDraw field");

					if (!isVisible)
					{
						fieldDraw = false;
						break;
					}

					var totalWidth = gfxData[index+4];

					var fieldXStart = gfxData[index+1] - dcX; // + gfxData[index+5];	// add x adjustment
					fieldYStart = displaySize - gfxData[index+2] - dcY;
			
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
			
					var fieldAscent = (gfxData[index+5] & 0xFF);
					var fieldDescent = ((gfxData[index+5] & 0xFF00) >> 8);
			
					fieldDraw = ((fieldXStart<=dcWidth && (fieldXStart+totalWidth)>=0 && (fieldYStart-fieldAscent)<=dcHeight && (fieldYStart+fieldDescent)>=0));
			
					fieldX = fieldXStart;

					if (isEditor)
					{
						gfxFieldHighlight(dc, index, fieldXStart, fieldYStart-fieldAscent, totalWidth, fieldAscent+fieldDescent);
					}

//	dc.setColor(Graphics.COLOR_RED, -1/*COLOR_TRANSPARENT*/);
//	dc.fillRectangle(fieldXStart, fieldYStart-fieldAscent, totalWidth, fieldAscent+fieldDescent);
					break;
				}

				case 2:		// large (hour, minute, colon)
				{
        			//System.println("gfxDraw large");

					if (!(fieldDraw && isVisible))
					{
						break;
					}

					var resourceIndex = ((gfxData[index+2/*large_font*/] >> 16) & 0xFF);
					var dynamicResource = getDynamicResource(resourceIndex);
					
					var timeY = fieldYStart;
					if (dynamicResource != null)
					{
						timeY -= Graphics.getFontAscent(dynamicResource);		// subtract ascent
					}

					if (isEditor)
					{
						gfxElementHighlight(dc, index, fieldX, timeY);
					}

					if (dynamicResource==null)
					{
						break;
					}

			
//	// font ascent & font height are all over the place with system fonts on different watches
//	// - have to hard code some values for each font and for each watch?
//	dc.setColor(Graphics.COLOR_RED, -1/*COLOR_TRANSPARENT*/);
//	dc.fillRectangle(fieldX, timeY, gfxData[index+4]+gfxData[index+6], Graphics.getFontHeight(dynamicResource));

//System.println("ascent=" + Graphics.getFontAscent(dynamicResource));
					
					if (gfxData[index+5]>0)	// width 1
					{
						if (fieldX<=dcWidth && (fieldX+gfxData[index+5])>=0)		// check digit x overlaps buffer
						{
							// align bottom of text
				       		dc.setColor(getColor64FromGfx(gfxData[index+3/*large_color*/]), -1/*COLOR_TRANSPARENT*/);
//	dc.setColor(getColor64FromGfx(gfxData[index+1]), Graphics.COLOR_BLUE);
			        		dc.drawText(fieldX, timeY - 1, dynamicResource, gfxData[index+4].toString(), 2/*TEXT_JUSTIFY_LEFT*/);	// need to draw 1 pixel higher than expected ...
						}
													
		        		fieldX += gfxData[index+5];
		        	}

					if (fieldX<=dcWidth && (fieldX+gfxData[index+7])>=0)		// check digit x overlaps buffer
					{
			       		dc.setColor(getColor64FromGfx(gfxData[index+3/*large_color*/]), -1/*COLOR_TRANSPARENT*/);
		        		dc.drawText(fieldX, timeY - 1, dynamicResource, gfxData[index+6].toString(), 2/*TEXT_JUSTIFY_LEFT*/);	// need to draw 1 pixel higher than expected ...
					}

		        	fieldX += gfxData[index+7];

					break;
				}
				
				case 3: 	// string
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
							var resourceIndex = ((gfxData[index+2/*string_font*/] >> 16) & 0xFF);
							var dynamicResource = getDynamicResource(resourceIndex);							

							var dateY = fieldYStart;
							if (dynamicResource!=null)
							{
								dateY -= Graphics.getFontAscent(dynamicResource);		// subtract ascent
							}
						
							if (isEditor)
							{
								gfxElementHighlight(dc, index, fieldX, dateY);
							}

							if (dynamicResource==null)
							{
								break;
							}

					        dc.setColor(getColor64FromGfx(gfxData[index+3/*string_color*/]), -1/*COLOR_TRANSPARENT*/);

							var s = StringUtil.charArrayToString(gfxCharArray.slice(sLen, eLen));
			        		dc.drawText(fieldX, dateY - 1, dynamicResource, s, 2/*TEXT_JUSTIFY_LEFT*/);		// need to draw 1 pixel higher than expected ...

							if ((gfxData[index+2/*string_font*/]&0x80000000)!=0)		// diacritics flag
							{
								var num = eLen - sLen;
								for (var i=0; i<num; i++)
								{
									var c = gfxCharArray[eLen+i];
									if (c!=0)
									{
										var w = ((i>0) ? dc.getTextWidthInPixels(s.substring(0, i), dynamicResource) : 0); 
										dc.drawText(fieldX + w, dateY - 1, dynamicResource, c.toString(), 2/*TEXT_JUSTIFY_LEFT*/);	// need to draw 1 pixel higher than expected ...
									}
								}
							}	
						}
								
			        	fieldX += gfxData[index+6];
					}

					break;
				}
				
				case 4:		// icon
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
							var resourceIndex = ((gfxData[index+2/*icon_font*/] >> 16) & 0xFF);
							var dynamicResource = getDynamicResource(resourceIndex);

							var dateY = fieldYStart;
							if (dynamicResource!=null)
							{
								dateY -= Graphics.getFontAscent(dynamicResource);		// subtract ascent
							}
						
							if (isEditor)
							{
								gfxElementHighlight(dc, index, fieldX, dateY);
							}
							
							if (dynamicResource==null)
							{
								break;
							}

					        dc.setColor(getColor64FromGfx(gfxData[index+3/*icon_color*/]), -1/*COLOR_TRANSPARENT*/);
			        		dc.drawText(fieldX, dateY - 1, dynamicResource, c.toString(), 2/*TEXT_JUSTIFY_LEFT*/);	// need to draw 1 pixel higher than expected ...
						}

			        	fieldX += gfxData[index+5];
					}

					break;
				}
				
				case 5:		// movebar
				{
					if (!(fieldDraw && isVisible))
					{
						break;
					}

					var resourceIndex = ((gfxData[index+2/*movebar_font*/] >> 16) & 0xFF);
					var dynamicResource = getDynamicResource(resourceIndex);

					var dateX = fieldX;
					var dateY = fieldYStart;
					if (dynamicResource!=null)
					{
						dateY -= Graphics.getFontAscent(dynamicResource);		// subtract ascent
					}

					if (isEditor)
					{
						gfxElementHighlight(dc, index, fieldX, dateY);
					}

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

						if (dateX<=dcWidth && (dateX+w)>=0)		// check element x overlaps buffer
						{ 
							var col = ((barIsOn || gfxData[index+8]==(COLOR_NOTSET+2/*COLOR_SAVE*/)) ? getColor64FromGfx(gfxData[index+3+i]) : getColor64FromGfx(gfxData[index+8]));
							
					        dc.setColor(col, -1/*COLOR_TRANSPARENT*/);
			        		dc.drawText(dateX, dateY - 1, dynamicResource, s, 2/*TEXT_JUSTIFY_LEFT*/);	// need to draw 1 pixel higher than expected ...
						}
						
						dateX += w + ((i<4) ? -5 : 0);
					}

		        	fieldX += gfxData[index+10];

					break;
				}
				
				case 6:		// chart
				{
					if (!(fieldDraw && isVisible))
					{
						break;
					}

					if (isEditor)
					{
						gfxElementHighlight(dc, index, fieldX, fieldYStart-21/*heartChartHeight*/);
					}

					if (fieldX<=dcWidth && (fieldX+gfxData[index+4])>=0)	// check element x overlaps buffer
					{
						var axesSide = ((gfxData[index+1]&0x01)!=0);
						var axesBottom = ((gfxData[index+1]&0x02)!=0);
	
						drawHeartChart(dc, fieldX, fieldYStart, getColor64FromGfx(gfxData[index+2]), getColor64FromGfx(gfxData[index+3]), axesSide, axesBottom);		// draw heart rate chart
					}

		        	fieldX += gfxData[index+4];

					break;
				}
				
				case 7:		// rectangle
				{
					if (!isVisible)
					{
						break;
					}

					var w = gfxData[index+6/*rect_w*/];
					var h = gfxData[index+7/*rect_h*/];
					var x = gfxData[index+4/*rect_x*/] - dcX - w/2;
					var y = displaySize - gfxData[index+5/*rect_y*/] - dcY - h/2;

					if (x<=dcWidth && (x+w)>=0 && y<=dcHeight && (y+h)>=0)
					{
						//var dataType = gfxData[index+1/*rect_type*/];
						//var colUnfilled = getColor64FromGfx(gfxData[index+3/*rect_unfilled*/]);

						var colFilled = getColor64FromGfx(gfxData[index+2/*rect_filled*/]);
						if (colFilled!=COLOR_NOTSET)
						{
					        dc.setColor(colFilled, -1/*COLOR_TRANSPARENT*/);
							dc.fillRectangle(x, y, w, h);
						}
					}

					if (isEditor)
					{
						gfxFieldHighlight(dc, index, x, y, w, h);
					}

					break;
				}
				
				case 8:	// ring
				{
					if (!isVisible)
					{
						break;
					}

					var resourceIndex = ((gfxData[index+2/*ring_font*/] >> 16) & 0xFF);
					var dynamicResource = getDynamicResource(resourceIndex);
					var arrayResource = getDynamicResource(gfxData[index+9]);					
					if (dynamicResource==null || arrayResource==null)
					{
						break;
					}

					var drawStart = gfxData[index+3];	// 0-59
					var drawEnd = gfxData[index+4];		// 0-59

					var fillStart = (gfxData[index+8]&0xFF);
					var fillEnd = ((gfxData[index+8]>>8)&0xFF);
					var noFill = ((gfxData[index+8]&0x10000)!=0);
					var fillValue = fillEnd;

					var eDirAnti = ((gfxData[index+1] & 0x40) != 0);	// false==clockwise
					if (eDirAnti)	// swap start & end for clockwise drawing
					{
						var temp = drawStart;
						drawStart = drawEnd;
						drawEnd = temp;
						
						// this makes it look odd when then adjust start or end - so removed it
						// if full circle
						//if (outerAlignedToSeconds(arrayResource) && drawStart==((drawEnd+1)%60))
						//{
						//	// shift clockwise one
						//	fillStart = ((fillStart+1)%60);
						//	fillEnd = ((fillEnd+1)%60);
						//}

						fillValue = fillStart;
					}
					
					var drawRange = (drawEnd - drawStart + 60)%60;	// 0-59

//					//var outerSizeHalf = getOuterSizeHalf(arrayResource);
//					var outerSizeHalf = arrayResource[61];
//					var bufferXMin = bufferX - outerSizeHalf;
//					var bufferXMax = bufferX + outerSizeHalf + 62/*BUFFER_SIZE*/;
//					var bufferYMin = bufferY - outerSizeHalf;
//					var bufferYMax = bufferY + outerSizeHalf + 62/*BUFFER_SIZE*/;

					var jStart = 0;
					var jRange = 59;	// all segments
					
					// Calculate the segment range which is inside the buffer area (as best we can while being cheap)
					// - check for quarter & half segments
					if (toBuffer)
					{
						jRange = 16;
						if (bufferX>=displayHalf)
						{
							if (bufferY>=displayHalf)
							{
								jStart = 14;
							}
							else if ((bufferY+62/*BUFFER_SIZE*/)<=displayHalf)
							{
								jStart = 59;
							}
							else
							{
								jStart = 7;
							}
						}
						else if ((bufferX+62/*BUFFER_SIZE*/)<=displayHalf)
						{
							if (bufferY>=displayHalf)
							{
								jStart = 29;
							}
							else if ((bufferY+62/*BUFFER_SIZE*/)<=displayHalf)
							{
								jStart = 44;
							}
							else
							{
								jStart = 37;
							}
						}
						else
						{
							if (bufferY<=displayHalf)
							{
								jStart = 52;
							}
							else
							{
								jStart = 22;
							}
						}
	
//						//if (bufferXMin > getMax(getOuterX(arrayResource, 59), getOuterX(arrayResource, 30)))
//						if (bufferXMin > getMax(arrayResource[59]&0xFFFF, arrayResource[30]&0xFFFF))
//						{
//							// right half only
//							//jStart = 0;
//							jRange = 29;
//						}
//						//else if (bufferXMax < getMin(getOuterX(arrayResource, 0), getOuterX(arrayResource, 29)))
//						else if (bufferXMax < getMin(arrayResource[0]&0xFFFF, arrayResource[29]&0xFFFF))
//						{
//							// left half only
//							jStart = 30;
//							jRange = 29;
//						}
//						
//						//if (bufferYMin > getMax(getOuterY(arrayResource, 14), getOuterY(arrayResource, 45)))
//						if (bufferYMin > getMax((arrayResource[14]>>16)&0xFFFF, (arrayResource[45]>>16)&0xFFFF))
//						{
//							// bottom half only
//							if (jRange==59)
//							{
//								jStart = 15;
//								jRange = 29;
//							}
//							else
//							{
//								jStart = ((jStart==0) ? 15 : 30);
//								jRange = 14;	// 15->29 or 30->44 
//							}
//						}
//						//else if (bufferYMax < getMin(getOuterY(arrayResource, 44), getOuterY(arrayResource, 15)))
//						else if (bufferYMax < getMin((arrayResource[44]>>16)&0xFFFF, (arrayResource[15]>>16)&0xFFFF))
//						{
//							// top half only
//							if (jRange==59)
//							{
//								jStart = 45;
//								jRange = 29;
//							}
//							else
//							{
//								jStart = ((jStart==0) ? 0 : 45);
//								jRange = 14;	// 0->14 or 45->59 
//							}
//						}
					}
					
//System.println("drawStart=" + drawStart + " drawEnd=" + drawEnd);
//System.println("jStart=" + jStart + " jRange=" + jRange);

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
					
					// do a check that at least some of the visible segments are inside the buffer range
					// the start or end of the shorter range MUST be inside the larger range 
					if (!((loopStart-testStart+60)%60<=testRange || (loopEnd-testStart+60)%60<=testRange))
					{
						break; 
					}

					var colFilled = getColor64FromGfx(gfxData[index+5]);
					var colValue = getColor64FromGfx(gfxData[index+6]);
					if (colValue==COLOR_NOTSET)
					{
						colValue = colFilled;
					}
					var colUnfilled = getColor64FromGfx(gfxData[index+7]);
					
					if (noFill)
					{
						colFilled = colUnfilled;
						colValue = colUnfilled;
					}
		
					//var outerSizeHalf = getOuterSizeHalf(arrayResource);
					var outerSizeHalf = arrayResource[61];
					var bufferXMin = bufferX - outerSizeHalf;
					var bufferXMax = bufferX + outerSizeHalf + 62/*BUFFER_SIZE*/;
					var bufferYMin = bufferY - outerSizeHalf;
					var bufferYMax = bufferY + outerSizeHalf + 62/*BUFFER_SIZE*/;

					var xOffset = -dcX - outerSizeHalf;
					var yOffset = -dcY - outerSizeHalf - 1;		// need to draw 1 pixel higher than expected ...
					var curCol = COLOR_NOTSET;
			
					// draw the correct segments
					for (var j=loopStart; j<=loopEnd; j++)
					{
						var index = j%60;
						
						//var outerX = getOuterX(arrayResource, index);		// calling these functions is a lot more expensive in partial update watchface diagnostics
						//var outerY = getOuterY(arrayResource, index);
						var xyVal = arrayResource[index];
						var outerX = (xyVal & 0xFFFF);
						var outerY = ((xyVal>>16) & 0xFFFF);

						// don't draw if not inside buffer
						// don't draw segments outside the other range we are testing
						//var testOffset = (index-testStart+60)%60;
						//if (testOffset>testRange)
						if ((toBuffer && (bufferXMin>outerX || bufferXMax<outerX || bufferYMin>outerY || bufferYMax<outerY)) ||
							(((index-testStart+60)%60)>testRange))
						{
							continue; 
						}
								
						var indexCol;
						if (index==fillValue)
						{
							indexCol = colValue;
						}
						else if (fillStart<=fillEnd)
						{
							indexCol = ((index>=fillStart && index<=fillEnd) ? colFilled : colUnfilled); 
						}
						else
						{
							indexCol = ((index>=fillStart || index<=fillEnd) ? colFilled : colUnfilled); 
						}

						if (indexCol != COLOR_NOTSET)	// don't draw the segment if no color is set
						{
							if (curCol!=indexCol)
							{
								curCol = indexCol;
			       				dc.setColor(curCol, -1/*COLOR_TRANSPARENT*/);
			       			}
		
							// test fill whole background of each character
			       			//dc.setColor(Graphics.COLOR_DK_BLUE, -1/*COLOR_TRANSPARENT*/);
				        	//dc.fillRectangle(xOffset + outerX, yOffset + outerY + 1, 16, 16);
			       			//dc.setColor(curCol, Graphics.COLOR_BLUE);
			       				
							//var s = characterString.substring(index, index+1);
							//var s = StringUtil.charArrayToString([(index + OUTER_FIRST_CHAR_ID).toChar()]);
							//var s = (index + 21/*OUTER_FIRST_CHAR_ID*/).toChar().toString();
				        	dc.drawText(xOffset + outerX, yOffset + outerY, dynamicResource, (index + 21/*OUTER_FIRST_CHAR_ID*/).toChar().toString(), 2/*TEXT_JUSTIFY_LEFT*/);
				        }
					}

					// test draw a line at top of display - so 0 really is the top visible pixel
			    	//dc.setClip(displayHalf, getOuterY(arrayResource,0)-8, 10, 1);
				    //dc.setColor(-1/*COLOR_TRANSPARENT*/, Graphics.COLOR_RED);
			        //dc.clear();
			    	//dc.clearClip();

					break;
				}
				
//				case 9:	// seconds
//				{
//					break;
//				}
			}
			
			//index += gfxSize(id);
			if (id<0 || id>=10/*GFX_SIZE_NUM*/)
			{
				break;
			}
			index += gfxSizeArray[id*2]; 	// cheaper with no function call in loop
		}
	}
}

(:m2app)
class myEditorView extends myView
{
	var timer;
	
	var editorFontResource;

	var propMenuColor = 0xFFFFFF;	// menu color
	var propMenuBorder = 0x000000;	// menu border
	var propFieldHighlight = 0xFFFFFF;
	var propElementHighlight = 0xFFFFFF;

    function initialize()
    {
		myView.initialize();
    }

	function onLayout(dc)
	{
		// load in data values which are stored as byte arrays (to save memory) 
//		{
//			var tempResource = WatchUi.loadResource(Rez.JsonData.id_editorBytes);
//			for (var i=0; i<128; i++)
//			{
//				colorGridArray[i] = tempResource[8][i];
//			}
//			tempResource = null;
//		}

		isEditor = true;
	
		editorFontResource = WatchUi.loadResource(Rez.Fonts.id_editor);

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
		horizontal line
		vertical line

	save profile
	load profile
	reset (delete all)
	*/
	
	var menuItem;
	
	var menuFieldGfx = 0;
	var menuElementGfx = 0;

	var reloadDynamicResources = false;

	function checkReloadDynamicResources()
	{
		var temp = reloadDynamicResources;
		reloadDynamicResources = false; 
		return temp;
	}

	function gfxAddField(index)
	{
		index = gfxInsert(index, 1);
		if (index>=0)
		{
			gfxData[index+1] = displayHalf;	// x from left
			gfxData[index+2] = displayHalf;	// y from bottom
			gfxData[index+3] = 0;	// justification (0==centre, 1==left, 2==right)
			// total width
			// ascent & descent
		}
		return index;
	}

	function gfxAddLarge(index, dataType)	// 0==hour large, 1==minute large, 2==colon large 
	{
		index = gfxInsert(index, 2);
		if (index>=0)
		{
			gfxData[index+1/*large_type*/] = dataType;		// type
			gfxData[index+2/*large_font*/] = getLastFontLarge(index);
			gfxData[index+3/*large_color*/] = COLOR_FOREGROUND+2/*COLOR_SAVE*/;	// color
			// string 0
			// width 0
			// string 1
			// width 1

			reloadDynamicResources = true;
		}
		return index;
	}

	function gfxAddString(index, dataType)
	{
		index = gfxInsert(index, 3);
		if (index>=0)
		{
			gfxData[index+1] = dataType;		// type + useNumFont
			gfxData[index+2/*string_font*/] = getLastFontString(index);
			gfxData[index+3/*string_color*/] = COLOR_FOREGROUND+2/*COLOR_SAVE*/;	// color
			// string start
			// string end
			// width

			reloadDynamicResources = true;
		}
		return index;
	}

	function gfxAddIcon(index, iconType)
	{
		index = gfxInsert(index, 4);
		if (index>=0)
		{
			gfxData[index+1] = iconType;	// type
			gfxData[index+2/*icon_font*/] = getLastFontIcon(index);	// font
			gfxData[index+3/*icon_color*/] = COLOR_FOREGROUND+2/*COLOR_SAVE*/;	// color
			// char
			// width

			reloadDynamicResources = true;
		}
		return index;
	}

	function gfxAddMoveBar(index)
	{
		index = gfxInsert(index, 5);
		if (index>=0)
		{
			gfxData[index+1] = 0;	// type
			gfxData[index+2/*movebar_font*/] = getLastFontIcon(index);	// font
			gfxData[index+3] = COLOR_FOREGROUND+2/*COLOR_SAVE*/;	// color 1
			gfxData[index+4] = COLOR_FOREGROUND+2/*COLOR_SAVE*/;	// color 2
			gfxData[index+5] = COLOR_FOREGROUND+2/*COLOR_SAVE*/;	// color 3
			gfxData[index+6] = COLOR_FOREGROUND+2/*COLOR_SAVE*/;	// color 4
			gfxData[index+7] = COLOR_FOREGROUND+2/*COLOR_SAVE*/;	// color 5
			gfxData[index+8] = COLOR_NOTSET+2/*COLOR_SAVE*/;	// color off
			// level to draw
			// width

			reloadDynamicResources = true;
		}
		return index;
	}

	function gfxAddChart(index)
	{
		index = gfxInsert(index, 6);
		if (index>=0)
		{
			gfxData[index+1] = 0;	// type
			gfxData[index+2] = COLOR_FOREGROUND+2/*COLOR_SAVE*/;	// color chart
			gfxData[index+3] = COLOR_FOREGROUND+2/*COLOR_SAVE*/;	// color axes
			// width
		}
		return index;
	}

	function gfxAddRectangle(index)
	{
		index = gfxInsert(index, 7);
		if (index>=0)
		{
			gfxData[index+1/*rect_type*/] = 0;	// type & direction
			gfxData[index+2/*rect_filled*/] = COLOR_FOREGROUND+2/*COLOR_SAVE*/;	// color filled
			gfxData[index+3/*rect_unfilled*/] = COLOR_NOTSET+2/*COLOR_SAVE*/;	// color unfilled
			gfxData[index+4/*rect_x*/] = displayHalf;	// x from left
			gfxData[index+5/*rect_y*/] = displayHalf;	// y from bottom
			gfxData[index+6/*rect_w*/] = 20;	// width
			gfxData[index+7/*rect_h*/] = 20;	// height
			// start fill, end fill & no fill flag
		}
		return index;
	}

	function gfxAddRing(index)
	{
		index = gfxInsert(index, 8);
		if (index>=0)
		{
			gfxData[index+1] = 0;	// type & direction
			gfxData[index+2/*ring_font*/] = 11/*SECONDFONT_OUTER*/;
			gfxData[index+3] = 0;	// start
			gfxData[index+4] = 59;	// end
			gfxData[index+5] = COLOR_FOREGROUND+2/*COLOR_SAVE*/;	// color filled
			gfxData[index+6] = COLOR_NOTSET+2/*COLOR_SAVE*/;	// color value
			gfxData[index+7] = COLOR_NOTSET+2/*COLOR_SAVE*/;	// color unfilled
			// start fill, end fill & no fill flag
			// xy array resource index

			reloadDynamicResources = true;
		}
		return index;
	}

	function gfxAddSeconds(index)
	{
		index = gfxInsert(index, 9);
		if (index>=0)
		{
			gfxData[index+1] = 0;			// font
			//gfxData[index+1] |= (0 << 8);	// refresh style
			gfxData[index+2] = COLOR_FOREGROUND+2/*COLOR_SAVE*/; // color
			gfxData[index+3] = COLOR_NOTSET+2/*COLOR_SAVE*/; // color5
			gfxData[index+4] = COLOR_NOTSET+2/*COLOR_SAVE*/; // color10
			gfxData[index+5] = COLOR_NOTSET+2/*COLOR_SAVE*/; // color15
			gfxData[index+6] = COLOR_NOTSET+2/*COLOR_SAVE*/; // color0
			// xy array resource index

			reloadDynamicResources = true;
		}
		return index;
	}

	function getLastFontLarge(index)
	{
		// 0-9 (half fonts), 10-45 (s,m,l fonts), 46-49 (4 system number fonts) + resourceIndex + fontIndex
		return getLastFont(index, 2, -1, 2/*large_font*/, 25/*m regular*/, 0);
	}

	function getLastFontString(index)
	{
		// 0-14 (s,m,l fonts), 15-19 (5 system fonts) + diacritics
		return getLastFont(index, 3, -1, 2/*string_font*/, 7/*m_regular*/, 1);
	}
	
	function getLastFontIcon(index)
	{
		// icon or movebar
		// luckily 2/*icon_font*/ == 2/*movebar_font*/
		return getLastFont(index, 4, 5, 2/*icon_font*/, 0, 2);
	}

	var lastFontArray = [-1, -1, -1];	// large, string, icon
	
	function getLastFont(index, id1, id2, gfxOffset, defaultFont, lastFontArrayIndex)
	{
		var f = -1;

		// look for previous font in same field
		for (var i=index; f<0; )
		{
			i = prevGfx(i);
			if (i<0 || gfxIsField(i))
			{
				break;
			}
			
			var id = getGfxId(i);
			if (id==id1 || id==id2)
			{
				f = (gfxData[i+gfxOffset]&0xFF);
			}
		}
		
		// look for next font in same field
		for (var i=index; f<0; )
		{
			i = nextGfx(i);
			if (i<0 || gfxIsField(i))
			{
				break;
			}
			
			var id = getGfxId(i);
			if (id==id1 || id==id2)
			{
				f = (gfxData[i+gfxOffset]&0xFF);
			}
		}
		
		if (f<0)
		{
			// search for first large font in any field (that is not itself!!)
			for (var i=0; lastFontArray[lastFontArrayIndex]<0; )
			{
				i = nextGfx(i);
				if (i<0)
				{
					break;
				}
				
				var id = getGfxId(i);
				if ((id==id1 || id==id2) && i!=index)	// right type but not itself
				{
					lastFontArray[lastFontArrayIndex] = (gfxData[i+gfxOffset]&0xFF);
				}
			}

			// use the last large font that the user used
			f = lastFontArray[lastFontArrayIndex];
		}
		
		if (f<0)
		{
			f = defaultFont;
		}

		return f;
	}

	function gfxDelete(index)
	{
		var id = getGfxId(index);
		var size = gfxSize(id);
		for (var i=index+size; i<gfxNum; i++)
		{
			gfxData[i-size] = gfxData[i];
		}
		gfxNum -= size;
	}

	function nextGfx(index)
	{
		var id = getGfxId(index);
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

			var id = getGfxId(temp);
			temp += gfxSize(id);
		}
		
		return ((prevIndex<gfxNum) ? prevIndex : -1);
	}

	function gfxIsField(index)
	{
		var id = getGfxId(index);
		return (id<=1 || id>=7);
		
//		switch(id)
//		{
//			case 0:		// header
//			case 1:		// field
//			case 7:		// rectangle
//			case 8:		// ring
//			case 9:		// seconds
//			{
//				return true;
//			}
//
//			case 2:		// large (hour, minute, colon)
//			case 3:		// string
//			case 4:		// icon
//			case 5:		// movebar
//			case 6:		// chart
//			{
//				break;
//			}
//		}
//		return false;
	}

	function afterGfxField(index)
	{
		var afterIndex = nextGfxField(index);
		if (afterIndex<0)
		{
			afterIndex = gfxNum;
		}
		return afterIndex;
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
		switchColorEditingMode();	// do this before menu handles select so that we don't change when first start editing a color

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

	const MAX_PROFILE_STRING_LENGTH = 255*2;

	var lastProfileStringLength = 0;
	
	function getUsedProfileStringLength()
	{
		return lastProfileStringLength.toFloat()/MAX_PROFILE_STRING_LENGTH; 
	}
	
	function copyGfxToPropertyString()
	{
		var charArray = gfxToCharArray();
		lastProfileStringLength = charArray.size();

		var s2 = "";

		if (charArray.size()>255)
		{
			var charArray2 = charArray.slice(255, charArray.size());
			s2 = StringUtil.charArrayToString(charArray2);
			if (s2==null)
			{
				s2 = "";
			}
			
			charArray2 = null;	// free up memory as no longer needed

			charArray = charArray.slice(0, 255);
		}

		var s = StringUtil.charArrayToString(charArray);
		if (s==null)
		{
			s = "";
		}

		charArray = null;	// free up memory as no longer needed
		
		applicationProperties.setValue("EP", s);
		applicationProperties.setValue("EP2", s2);
	}

	var getColorGfxIndex = -1;
	
	// menu+gfx, menu+grid+gfx, grid+gfx, grid, gfx
	var colorEditingMode = 1;

	var menuHide = false;
	var menuY = 50;
	
	function isMenuAtTop()
	{
		return (menuY<120);
	}
	
	// off, 1 bar, all bars
	var memoryDisplayMode = 1;

    function onUpdate(dc)
    {
    	if (reloadDynamicResources)
    	{
    		// reloading the dynamic resources causes the gfx to be read from "EP" so update it first!
			copyGfxToPropertyString();
    	}
    
    	doDrawGfx = (!isColorEditing() || (colorEditingMode!=3));
    
    	myView.onUpdate(dc);	// draw the normal watchface
    	
    	if (true)
    	{
    		// make sure "EP" is up to date at the end of every frame!
    		copyGfxToPropertyString();
		}

		//drawAbc(dc);

    	if (isColorEditing() && (colorEditingMode>=1 && colorEditingMode<=3))
		{
    		drawColorGrid(dc);
    	}
    	
    	if (!menuHide && (!isColorEditing() || (colorEditingMode<=1)))
		{
	    	var x = (displaySize*25)/240;
	    	var y = (displaySize*menuY)/240;
	
	    	drawMenu(dc, x, y);    	// then draw any menus on top
	    	
	    	drawMemory(dc, x, y);	// draw a memory indicator
		}
    }

	function gfxAddDynamicResources(fontIndex)
	{	
		if (gfxNum>0 && getGfxId(0)==0)		// header - calculate values from this here so similar to gfxOnUpdate
		{
			gfxData[0+5] = getMinMax(gfxData[0+5], COLOR_FOREGROUND+2/*COLOR_SAVE*/, 63+2/*COLOR_SAVE*/);	// propMenuColor
			gfxData[0+6] = getMinMax(gfxData[0+6], COLOR_NOTSET+2/*COLOR_SAVE*/, 63+2/*COLOR_SAVE*/);	// propMenuBorder
			gfxData[0+7] = getMinMax(gfxData[0+7], COLOR_NOTSET+2/*COLOR_SAVE*/, 63+2/*COLOR_SAVE*/);	// propFieldHighlight
			gfxData[0+8] = getMinMax(gfxData[0+8], COLOR_NOTSET+2/*COLOR_SAVE*/, 63+2/*COLOR_SAVE*/);	// propElementHighlight
		}
		
		return myView.gfxAddDynamicResources(fontIndex);
	}
	
	function gfxOnUpdate(dc, clockTime, timeNow)
	{
		if (gfxNum>0 && getGfxId(0)==0)		// header - calculate values from this here as they are used early ...
		{
			propMenuColor = getColor64FromGfx(gfxData[0+5]);
			propMenuBorder = getColor64FromGfx(gfxData[0+6]);
			propFieldHighlight = getColor64FromGfx(gfxData[0+7]);
			propElementHighlight = getColor64FromGfx(gfxData[0+8]);
		}

    	myView.gfxOnUpdate(dc, clockTime, timeNow);

		// make sure either the menu or border color is different from the background
		if (propMenuBorder==propMenuColor && propMenuBorder==propBackgroundColor)
		{
			propMenuBorder = ((propBackgroundColor==0) ? 0xFFFFFF : 0x000000); 
		}
	}
	
    function drawMenu(dc, x, y)
    {
    	//var xEnd = x + 30;
   
 		y = y-1;	// all drawText calls need to draw 1 pixel higher than expected ...
  
    	var eStr = menuItem.getString();
    	
    	if (isColorEditing())
    	{
    		eStr = geColorName();
    	}
    	
		if (eStr != null)
		{
			var xText = x + 42;
			var yText = y;
			
			if (isMenuAtTop())
			{
				yText -= Graphics.getFontAscent(Graphics.FONT_SYSTEM_TINY);
			}
			else
			{
				var textSize = dc.getTextDimensions(eStr, Graphics.FONT_SYSTEM_TINY);
				yText -= textSize[1];
				yText += Graphics.getFontDescent(Graphics.FONT_SYSTEM_TINY);
			}
		
			// following only works on 3.1.0 +
			//eStr = Graphics.fitTextToArea(eStr, Graphics.FONT_SYSTEM_TINY, editorView.displaySize - xText - x*1.5, editorView.displaySize, true);
		
			drawMultiText(dc, eStr, xText, yText, Graphics.FONT_SYSTEM_TINY);
			
			//xEnd = xText + dc.getTextWidthInPixels(eStr, Graphics.FONT_SYSTEM_TINY) + 5;
		}

//dc.setColor(Graphics.COLOR_WHITE, -1/*COLOR_TRANSPARENT*/);
//dc.fillPolygon([[120,120],[200,200],[120,200]]);

		// editorfont
		// A = 
		// B = 
		// C = up triangle
		// D = down triangle
		// E = left triangle
		// F = right triangle
		// G = rotating arrow

    	if (menuItem.hasDirection(2))	// left
    	{
			drawMultiText(dc, "E", x, y-15, editorFontResource);
		}

    	if (menuItem.hasDirection(0))	// up
    	{
			drawMultiText(dc, "C", x+13, y-20, editorFontResource);
		}

    	if (menuItem.hasDirection(1))	// down
    	{
			drawMultiText(dc, "D", x+13, y-10, editorFontResource);
		}

    	if (menuItem.hasDirection(3))	// right
    	{
			//drawText(dc, "F", xEnd, y-15, editorView.editorFontResource);
			drawMultiText(dc, "F", x+26, y-15, editorFontResource);
		}
    }
        
	function drawMultiText(dc, s, x, y, font)
	{
		if (propMenuBorder!=COLOR_NOTSET)
		{
	        dc.setColor(propMenuBorder, -1/*COLOR_TRANSPARENT*/);
//	        for (var i=-1; i<=1; i+=2)
//	        {
//	        	for (var j=-1; j<=1; j+=2)
//	        	{
//					dc.drawText(x + i, y + j, font, s, 2/*TEXT_JUSTIFY_LEFT*/);
//	        	}
//	        }
	        for (var i=-2; i<=2; i+=2)
	        {
	        	for (var j=-2; j<=2; j+=2)
	        	{
	        		if (i!=0 || j!=0)
	        		{
						dc.drawText(x + i, y + j, font, s, 2/*TEXT_JUSTIFY_LEFT*/);
					}
	        	}
	        }
		}
		        
        dc.setColor(propMenuColor, -1/*COLOR_TRANSPARENT*/);
        //dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        //dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
		//dc.drawText((editorView.displaySize*50)/240, (editorView.displaySize*50)/240, Graphics.FONT_SYSTEM_XTINY, eStr, 2/*TEXT_JUSTIFY_LEFT*/);
		dc.drawText(x, y, font, s, 2/*TEXT_JUSTIFY_LEFT*/);
	}
    
	function drawMemory(dc, x, y)
	{
		var usedProfileStringLength = getUsedProfileStringLength();
		var usedGfxData = getUsedGfxData();
		var usedCharArray = getUsedCharArray();
		var usedDynamicResourceNum = getUsedDynamicResourceNum();
		var usedResourceMemory = getUsedResourceMemory();

		var w = displaySize*0.4;
		var h = 4;

		//x = x + 42;
		x = displayHalf - w/2;
		y = (displaySize*(isMenuAtTop() ? 15 : 220))/240;
		
		if (memoryDisplayMode==2)	// all bars
		{
			if (!isMenuAtTop())
			{
				y -= (h-1)*4;
			}

			drawMemoryBar(dc, x, y, w, h, usedProfileStringLength);
			drawMemoryBar(dc, x, y+(h-1)*1, w, h, usedGfxData);
			drawMemoryBar(dc, x, y+(h-1)*2, w, h, usedCharArray);
			drawMemoryBar(dc, x, y+(h-1)*3, w, h, usedDynamicResourceNum);
			drawMemoryBar(dc, x, y+(h-1)*4, w, h, usedResourceMemory);
		}
		else if (memoryDisplayMode==1)	// 1 bar
		{
			// find the highest used fraction out of all the pools
			var frac = usedProfileStringLength;
			frac = getMax(frac, usedGfxData);
			frac = getMax(frac, usedCharArray);
			frac = getMax(frac, usedDynamicResourceNum);
			frac = getMax(frac, usedResourceMemory);
		
			drawMemoryBar(dc, x, y, w, h, frac);
		}
	}

	function drawMemoryBar(dc, x, y, w, h, frac)
	{
		dc.setColor(propMenuColor, -1/*COLOR_TRANSPARENT*/);
		dc.setPenWidth(1);		  
		dc.drawRectangle(x, y, w, h);

		var w2 = ((w-2)*frac).toNumber();
		dc.fillRectangle(x+1, y+1, w2, h-2);

		if (propMenuBorder!=COLOR_NOTSET)
		{
			dc.setColor(propMenuBorder, -1/*COLOR_TRANSPARENT*/);
			dc.fillRectangle(x+1+w2, y+1, w-2-w2, h-2);
		}
	}

	function gfxFieldHighlight(dc, index, x, y, w, h)
	{
		if (index==menuFieldGfx)
		{
			// only highlight the field itself when selecting fields (at the top level of menu)
			if ((getGfxId(menuFieldGfx)==1 && menuElementGfx==0) ||		// field
				(getGfxId(menuFieldGfx)==7 && menuItem!=null && (menuItem instanceof myMenuItemFieldSelect)))		// rectangle
			{
				if (propFieldHighlight!=COLOR_NOTSET)
				{
					//dc.setColor(Graphics.COLOR_BLUE, -1/*COLOR_TRANSPARENT*/);
					dc.setColor(propFieldHighlight, -1/*COLOR_TRANSPARENT*/);
				
					dc.setPenWidth(2);		  
					dc.drawRoundedRectangle(x-3, y-3, w+3+3+1, h+3+3+1, 3);
		
					//dc.setPenWidth(1);		  
					//dc.setPenWidth(2);	// pen width 2 is 1 pixel above, and 1 pixel left of all lines		  
					//dc.setPenWidth(3);	// pen width 3 is 1 pixel above & below, and 1 pixel left & right of all lines
					//dc.drawRectangle(x, y, w, h);
					//dc.drawRoundedRectangle(x, y, w, h, 3);
					//dc.drawRoundedRectangle(x-1, y-1, w+2, h+2, 3);
					//dc.fillRectangle(x, y, w, h);
				}
			}
						
			// make sure menu is at best position for editing this field
			if (isMenuAtTop())
			{
				if (y<(displaySize*80)/240)
				{
					menuY = 200;	// move to bottom
				}
			}
			else
			{
				if ((y+h)>(displaySize*160)/240)
				{
					menuY = 50;		// move to top
				}
			}
		}
	}

	function getResourceFontHeight(i)
	{
		var resourceIndex = ((gfxData[i] >> 16) & 0xFF);
		var dynamicResource = getDynamicResource(resourceIndex);
		return ((dynamicResource!=null) ? Graphics.getFontHeight(dynamicResource) : 1);
	}
		
	function gfxElementHighlight(dc, index, x, y)
	{
		if (index==menuElementGfx && propElementHighlight!=COLOR_NOTSET)
		{
			// moved calculation of width & height just into the editor to save code on the watchface
			var w = 1;
			var h = 1;
			var id = getGfxId(index);
			if (id==2)		// large (hour, minute, colon)
			{
				w = gfxData[index+5]+gfxData[index+7];
				h = getResourceFontHeight(index+2/*large_font*/);
			}
			else if (id==3)		// string
			{
				w = gfxData[index+6];
				h = getResourceFontHeight(index+2/*string_font*/);
			}
			else if (id==4)		// icon
			{
				w = gfxData[index+5];
				h = getResourceFontHeight(index+2/*icon_font*/);
			}
			else if (id==5)		// movebar
			{
				w = gfxData[index+10];
				h = getResourceFontHeight(index+2/*movebar_font*/);
			}
			else if (id==6)		// chart
			{
				w = gfxData[index+4];
				h = 21/*heartChartHeight*/;
			}

			//dc.setColor(Graphics.COLOR_RED, -1/*COLOR_TRANSPARENT*/);
			dc.setColor(propElementHighlight, -1/*COLOR_TRANSPARENT*/);

			dc.setPenWidth(2);		  
			dc.drawRoundedRectangle(x-3, y-3, w+3+3+1, h+3+3+1, 3);

			//dc.drawRectangle(x, y, w, h);
			//dc.drawRoundedRectangle(x-1, y-1, w+2, h+2, 3);
			//dc.fillRectangle(x, y, w, h);
		}
	}
	
	function startColorEditing(gfxIndex)
	{
		getColorGfxIndex = gfxIndex;
	}

	function switchColorEditingMode()
	{
		if (isColorEditing())
		{
			colorEditingMode = (colorEditingMode+1)%5;
		}
	}

	function endColorEditing()
	{
		getColorGfxIndex = -1;
	}

	function isColorEditing()
	{
		return (getColorGfxIndex != -1);
	}

	function drawColorGrid(dc)
	{
		// distance from centre (0-7) + clockwise angle (0-36)
		var colorGridArray = WatchUi.loadResource(Rez.JsonData.id_colorGridArray);
		if (colorGridArray!=null)
		{
			var highlightGrid = ((getColorGfxIndex>=0) ? (gfxData[getColorGfxIndex]-2/*COLOR_SAVE*/) : -1);
		
			var rScale = (displaySize*14 + 120)/240;
			var cScaleHighlight = (displaySize*7 + 120)/240;
			var cScale = (displaySize*4 + 120)/240;
	
			var hx = 0;
			var hy = 0;
			 
			for (var i=0; i<64; i++)
			{
		        var i2 = i * 2;
		        var r = colorGridArray[i2] * rScale;
		        var a = Math.toRadians(colorGridArray[i2+1] * 10);
		        var x = Math.round(r * Math.sin(a));
		        var y = Math.round(r * Math.cos(a));
		         
		        if (i==highlightGrid)
		        {
		        	hx = x;
		        	hy = y;
		        }
		         	        
		        dc.setColor(getColor64FromGfx(i+2/*COLOR_SAVE*/), -1/*COLOR_TRANSPARENT*/);	        
	    		//dc.drawText(displayHalf + x, displayHalf - y - 1, editorFontResource, (i==highlightGrid)?"B":"A", Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
	   			dc.fillCircle(displayHalf + x, displayHalf - y, (i==highlightGrid)?cScaleHighlight:cScale);
	   		}
	
	        if (highlightGrid>=0 && propMenuBorder!=COLOR_NOTSET)
	        {
	    		dc.setColor(propMenuBorder, -1/*COLOR_TRANSPARENT*/);
				dc.setPenWidth(3);		  
				dc.drawCircle(displayHalf + hx, displayHalf - hy, cScaleHighlight+1);
	        }
		}
	}

	function geColorName()
	{
		var colorNum = ((getColorGfxIndex>=0) ? gfxData[getColorGfxIndex] : 0);

		return safeStringFromJsonDataMulti(Rez.JsonData.id_colorStrings, Rez.JsonData.id_colorStrings2, Rez.JsonData.id_colorStrings3, colorNum);
	}

////	   		useDc.setColor(propTimeHourColor, -1/*COLOR_TRANSPARENT*/);
////	   		if (fontTimeHourResource!=null)		// sometimes onPartialUpdate is called between onSettingsChanged and onUpdate - so this resource could be null
////	   		{
////				useDc.drawText(120 - dcX, 120 - 105 - dcY, fontTimeHourResource, "012", graphics.TEXT_JUSTIFY_CENTER);
////				useDc.drawText(120 - dcX, 120 - 35 - dcY, fontTimeHourResource, "3456", graphics.TEXT_JUSTIFY_CENTER);
////				useDc.drawText(120 - dcX, 120 + 35 - dcY, fontTimeHourResource, "789:", graphics.TEXT_JUSTIFY_CENTER);
////			}

//	function drawAbc(dc)
//	{
//		dc.setColor(Graphics.COLOR_WHITE, -1/*COLOR_TRANSPARENT*/);
//		var dynamicResource = getDynamicResource(0);
//		if (dynamicResource!=null)
//   		{
//			//useDc.drawText(120 - dcX, 120 - 120 - dcY, fontFieldResource, " I:I1%", graphics.TEXT_JUSTIFY_CENTER);
//			//useDc.drawText(120 - dcX, 120 - 95 - dcY, fontFieldResource, "2345678", graphics.TEXT_JUSTIFY_CENTER);
//			//useDc.drawText(120 - dcX, 120 - 70 - dcY, fontFieldResource, "9-0\\/A.B,CD", graphics.TEXT_JUSTIFY_CENTER);
//			//useDc.drawText(120 - dcX, 120 - 45 - dcY, fontFieldResource, "EFGHIJKLMNO", graphics.TEXT_JUSTIFY_CENTER);
//			//useDc.drawText(120 - dcX, 120 - 20 - dcY, fontFieldResource, "PQRSTUVWXYZ", graphics.TEXT_JUSTIFY_CENTER);
//			//useDc.drawText(120 - dcX, 120 + 10 - dcY, fontFieldResource, "ÁÚÄÅÇÉÌÍÓÖØ", graphics.TEXT_JUSTIFY_CENTER);
//			//useDc.drawText(120 - dcX, 120 + 40 - dcY, fontFieldResource, "ÛÜÝĄČĚĽŁŃ", graphics.TEXT_JUSTIFY_CENTER);
//			//useDc.drawText(120 - dcX, 120 + 70 - dcY, fontFieldResource, "ŐŘŚŠŹŽ​", graphics.TEXT_JUSTIFY_CENTER);
//
//			var yOffsets = [-118, -93, -68, -43, -18, 12, 42, 72];
//			//var sArray = [" I:I1%", "2345678", "9-0\\/A.B,CD", "EFGHIJKLMNO", "PQRSTUVWXYZ", "ÁÚÄÅÇÉÌÍÓÖØ", "ÛÜÝĄČĚĽŁŃ", "ŐŘŚŠŹŽ​"];
//			var sArray = [" ", " ", "ABCD", "EFGHIJKLMNO", "PQRSTUVWXYZ", "ÁÚÄÅÇÉÌÍÓÖØ", "ÛÜÝĄČĚĽŁŃ", "ŐŘŚŠŹŽ​"];
//
//			for (var i=0; i<sArray.size(); i++)
//			{
//				var charArray = sArray[i].toCharArray();
//				
//				// calculate total width first
//				var totalWidth = 0;
//				for (var j=0; j<charArray.size(); j++)
//				{
//					var c = getMyCharDiacritic(charArray[j]);
//        			totalWidth += dc.getTextWidthInPixels(c[0].toString(), dynamicResource);
//				}
//				
//				var y = displayHalf + ((yOffsets[i]*displayHalf)/120);
//				var x = displayHalf - totalWidth/2;
//				
//				// draw each character + any diacritic
//				for (var j=0; j<charArray.size(); j++)
//				{
//					var c = getMyCharDiacritic(charArray[j]);						
//					dc.drawText(x, y, dynamicResource, c[0].toString(), 2/*TEXT_JUSTIFY_LEFT*/);
//	    			if (c[1]>700)
//	    			{
//						dc.drawText(x, y, dynamicResource, c[1].toChar().toString(), 2/*TEXT_JUSTIFY_LEFT*/);
//	    			}
//					x += dc.getTextWidthInPixels(c[0].toString(), dynamicResource);
//				}
//			}
//		}
//	}
	
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

//	function safeStringFromArray(arr, index)
//	{
//		return ((index>=0 && index<arr.size()) ? arr[index] : "unknown");
//	}

//	function safeStringFromStorage(key, index1, index2)
//	{
//		var tempArray = applicationStorage.getValue(key);
//		if (tempArray!=null)
//		{
//			if (index1>=0 && index1<tempArray.size())
//			{
//				tempArray = tempArray[index1];
//			}
//			
//			if (index2>=0 && index2<tempArray.size())
//			{
//				return tempArray[index2];
//			}
//		}
//		
//		return "unknown";
//	}

	function safeStringFromJsonData(r1, index1, index2)
	{
		var tempArray = WatchUi.loadResource(r1);
		if (tempArray!=null)
		{
			if (index1>=0 && index1<tempArray.size())
			{
				tempArray = tempArray[index1];
			}
			
			if (index2>=0 && index2<tempArray.size())
			{
				return tempArray[index2];
			}
		}
		
		return "unknown";
	}

	// split the string resource into multiple chunks to save memory ...
	function safeStringFromJsonDataMulti(r1, r2, r3, index)
	{
		if (index>=0)
		{
			var tempArray;
			
			if (r1!=null)
			{
				tempArray = WatchUi.loadResource(r1);
				if (tempArray!=null && index<tempArray.size())
				{
					return tempArray[index];
				}
				index -= tempArray.size();
				tempArray = null;
			}
			
			if (r2!=null)
			{
				tempArray = WatchUi.loadResource(r2);
				if (tempArray!=null && index<tempArray.size())
				{
					return tempArray[index];
				}
				index -= tempArray.size();
				tempArray = null;
			}
			
			if (r3!=null)
			{
				tempArray = WatchUi.loadResource(r3);
				if (tempArray!=null && index<tempArray.size())
				{
					return tempArray[index];
				}
			}
		}
				
		return "unknown";
	}

	function getGfxName(index)
	{
		var id = getGfxId(index);
		
		if (id==2)			// large (hour, minute, colon)
		{
			return getLargeTypeName(gfxData[index+1]);
		}
		else if (id==3)		// string
		{
			return getStringTypeName(gfxData[index+1]);
		}
		else if (id==8)		// ring
		{
 			return safeStringFromJsonData(Rez.JsonData.id_ringNameStrings, -1, ringGetTypeFromGfxIndex(index));    		
		}
		else
		{
			return safeStringFromJsonData(Rez.JsonData.id_gfxNameStrings, -1, id);
		}
	}

	function getLargeTypeName(eDisplay)
	{
		return safeStringFromJsonData(Rez.JsonData.id_largeTypeStrings, -1, eDisplay);
	}

	function getStringTypeName(eDisplay)
	{
		return safeStringFromJsonDataMulti(Rez.JsonData.id_stringTypeStrings, Rez.JsonData.id_stringTypeStrings2, Rez.JsonData.id_stringTypeStrings3, (eDisplay&0x7F)-1);
	}

	function getVisibilityString(vis)
	{
		return safeStringFromJsonData(Rez.JsonData.id_visibilityStrings, -1, vis);
	}
	
	function fieldVisibilityString()
	{
		return getVisibilityString(fieldGetVisibility());
	}

	function fieldGetVisibility()
	{
		return ((gfxData[menuFieldGfx] >> 8) & 0xFF);
	}

	function fieldVisibilityEditing(val)
	{
		val = (fieldGetVisibility()+val+25/*STATUS_NUM*/)%25/*STATUS_NUM*/;

		gfxData[menuFieldGfx] &= ~(0xFF << 8);
		gfxData[menuFieldGfx] |= ((val & 0xFF) << 8);
	}

	function fieldPositionGetX()
	{
		return gfxData[menuFieldGfx+1];
	}

	function fieldPositionGetY()
	{
		return gfxData[menuFieldGfx+2];
	}

	function fieldPositionXEditing(val)
	{
		gfxData[menuFieldGfx+1] = getMinMax(gfxData[menuFieldGfx+1]-val, 0, displaySize);
	}

	function fieldPositionYEditing(val)
	{
		gfxData[menuFieldGfx+2] = getMinMax(gfxData[menuFieldGfx+2]-val, 0, displaySize);
	}

	function fieldPositionCentreX()
	{
		gfxData[menuFieldGfx+1] = displayHalf;
	}

	function fieldPositionCentreY()
	{
		var fieldAscent = (gfxData[menuFieldGfx+5] & 0xFF);
		gfxData[menuFieldGfx+2] = displayHalf - (fieldAscent+1)/2;	// subtract half the max ascent
	}

	function fieldGetAlignment()
	{
		return gfxData[menuFieldGfx+3];
	}

	function fieldAlignmentEditing(val)
	{
		gfxData[menuFieldGfx+3] = (gfxData[menuFieldGfx+3]+val+3)%3;
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
		var prevField = prevGfxField(menuFieldGfx);
		if (prevField>0)	// 0==header
		{
			fieldSwap(prevField, menuFieldGfx);

			menuFieldGfx = prevField;
		}

		reloadDynamicResources = true;		// if maxed out dynamic resources this may load different ones now
	}

	function fieldLater()
	{
		var nextField = nextGfxField(menuFieldGfx);
		if (nextField>=0)
		{
			menuFieldGfx = fieldSwap(menuFieldGfx, nextField);
		}

		reloadDynamicResources = true;		// if maxed out dynamic resources this may load different ones now
	}

	function fieldDelete()
	{
		var nextField = nextGfxField(menuFieldGfx);
		if (nextField>=0)
		{
			var diff = nextField - menuFieldGfx;
			for (var index=nextField; index<gfxNum; index++)
			{
				gfxData[index-diff] = gfxData[index];
			}
			
			gfxNum -= diff;
		}
		else
		{
			var prevField = prevGfxField(menuFieldGfx);
			
			gfxNum = menuFieldGfx;	// new end of array is current position
			 
			menuFieldGfx = prevField;	// new current position is previous field
		}

		reloadDynamicResources = true;
	}

	function fieldDeleteAll()
	{
		menuFieldGfx = 0;
		
		if (getGfxId(0)==0)		// should be a header gfx at 0
		{
			gfxNum = nextGfxField(0);
		}
		else
		{
			gfxNum = 0; 
			gfxAddHeader(gfxNum);	
		}
		
		reloadDynamicResources = true;
	}

	function headerBackgroundColorEditing(val)
	{
		gfxData[menuFieldGfx+3] = (gfxData[menuFieldGfx+3]-val+64-2/*COLOR_SAVE*/)%64 + 2/*COLOR_SAVE*/;	// 2 to 65
	}
	
	function headerForegroundColorEditing(val)
	{
		gfxData[menuFieldGfx+4] = (gfxData[menuFieldGfx+4]-val+64-2/*COLOR_SAVE*/)%64 + 2/*COLOR_SAVE*/;	// 2 to 65
	}
	
	function headerMenuColorEditing(val)
	{
		gfxData[menuFieldGfx+5] = (gfxData[menuFieldGfx+5]-val+65-1/*COLOR_ONE*/)%65 + 1/*COLOR_ONE*/;	// 1 to 65
	}
	
	function headerMenuBorderColorEditing(val)
	{
		gfxData[menuFieldGfx+6] = (gfxData[menuFieldGfx+6]-val+66)%66;	// 0 to 65
	}
	
	function headerFieldHighlightColorEditing(val)
	{
		gfxData[menuFieldGfx+7] = (gfxData[menuFieldGfx+7]-val+66)%66;	// 0 to 65
	}
	
	function headerElementHighlightColorEditing(val)
	{
		gfxData[menuFieldGfx+8] = (gfxData[menuFieldGfx+8]-val+66)%66;	// 0 to 65
	}
	
	function headerBatteryEditing(n, val)
	{
		var cur = gfxData[menuFieldGfx+10+n];
		if ((val<0 && cur>=10 && cur<=85) || (val>0 && cur>=15 && cur<=90))
		{
			val = val*5;
		} 
		gfxData[menuFieldGfx+10+n] = getMinMax(cur-val, 0, 100);	// 0 to 100
	}
	
	function headerBatteryAtMax(n)
	{
		return (gfxData[menuFieldGfx+10+n]>=100);	// 0 to 100
	}
	
	function headerBatteryAtMin(n)
	{
		return (gfxData[menuFieldGfx+10+n]<=0);	// 0 to 100
	}
	
	function header2ndTimeZoneEditing(val)
	{
		gfxData[menuFieldGfx+12] = getMinMax(gfxData[menuFieldGfx+12]-val, 0, 48);	// 0 to 48
	}
	
	function header2ndTimeZoneAtMax()
	{
		return (gfxData[menuFieldGfx+12]>=48);	// 0 to 48
	}
	
	function header2ndTimeZoneAtMin()
	{
		return (gfxData[menuFieldGfx+12]<=0);	// 0 to 48
	}
	
	function headerMoveBarAlertEditing(val)
	{
		gfxData[menuFieldGfx+13] = getMinMax(gfxData[menuFieldGfx+13]-val, 1, 5);		// 1 to 5
	}
	
	function headerMoveBarAlertAtMax()
	{
		return (gfxData[menuFieldGfx+13]>=5);	// 1 to 5
	}
	
	function headerMoveBarAlertAtMin()
	{
		return (gfxData[menuFieldGfx+13]<=1);	// 1 to 5
	}
	
	function headerFontSystemCaseEditing(val)
	{
		gfxData[menuFieldGfx+14] = (gfxData[menuFieldGfx+14]-val+3)%3;		// 0 to 2
	}
	
	function headerFontUnsupportedEditing(val)
	{
		gfxData[menuFieldGfx+15] = (gfxData[menuFieldGfx+15]-val+5)%5;		// 0 to 4
	}
	
	function elementVisibilityString()
	{
		return getVisibilityString(elementGetVisibility());
	}

	function elementGetVisibility()
	{
		return ((gfxData[menuElementGfx] >> 8) & 0xFF);
	}

	function elementVisibilityEditing(val)
	{
		val = (elementGetVisibility()+val+25/*STATUS_NUM*/)%25/*STATUS_NUM*/;

		gfxData[menuElementGfx] &= ~(0xFF << 8);
		gfxData[menuElementGfx] |= ((val & 0xFF) << 8);
	}

	function elementSwap(prevElement, nextElement)
	{
		var diff = nextElement - prevElement;
		var tempArray = gfxData.slice(prevElement, nextElement);
		
		var endElement = nextGfx(nextElement);
		if (endElement<0)
		{
			endElement = gfxNum;
		}

		for (var index=nextElement; index<endElement; index++)
		{
			gfxData[index-diff] = gfxData[index];
		}
		
		for (var index=0; index<diff; index++)
		{
			gfxData[endElement-diff+index] = tempArray[index];
		}
		
		return endElement-diff;	// new start index of new later field
	}

	function elementEarlier()
	{
		var prevElement = prevGfx(menuElementGfx);
		if (prevElement>menuFieldGfx)
		{
			elementSwap(prevElement, menuElementGfx);

			menuElementGfx = prevElement;
		}

		reloadDynamicResources = true;		// if maxed out dynamic resources this may load different ones now
	}

	function elementLater()
	{
		var nextElement = nextGfx(menuElementGfx);
		if (nextElement>=0)
		{
			if (nextElement<afterGfxField(menuFieldGfx))
			{ 
				menuElementGfx = elementSwap(menuElementGfx, nextElement);
			}
		}

		reloadDynamicResources = true;		// if maxed out dynamic resources this may load different ones now
	}

	function elementDelete()
	{
		gfxDelete(menuElementGfx);

		if (menuElementGfx>=afterGfxField(menuFieldGfx))
		{
			menuElementGfx = prevGfx(menuElementGfx);	// new current position is previous gfx
		}

		reloadDynamicResources = true;
	}

	function largeGetType()
	{
		return gfxData[menuElementGfx+1];
	}
		
	function largeTypeEditing(val)
	{
		gfxData[menuElementGfx+1] = (largeGetType()+val+3)%3;
		reloadDynamicResources = true;
	}
		
	function largeColorEditing(val)
	{
		gfxData[menuElementGfx+3/*large_color*/] = (gfxData[menuElementGfx+3/*large_color*/]-val+65-1/*COLOR_ONE*/)%65 + 1/*COLOR_ONE*/;	// 1 to 65
	}

	function largeGetFont()
	{
		return (gfxData[menuElementGfx+2/*large_font*/]&0xFF);
	}
		
	function largeFontEditing(val)
	{	
		gfxData[menuElementGfx+2/*large_font*/] = ((largeGetFont()-val+50)%50);	// 0-9 (half fonts), 10-45 (s,m,l fonts), 46-49 (4 system number fonts)
		reloadDynamicResources = true;

		lastFontArray[0] = gfxData[menuElementGfx+2/*large_font*/];
	}

	function stringGetType()
	{
		return gfxData[menuElementGfx+1];
	}
		
	function stringSetType(v)
	{
		gfxData[menuElementGfx+1] = v;
		reloadDynamicResources = true;
	}
		
    function stringTypeEditing(val, idArray, idArrayValue)
    {
		var tempArray = WatchUi.loadResource(Rez.JsonData.id_addStringArrays);
    	if (tempArray!=null)
    	{
    		if (idArray>=0 && idArray<tempArray.size())
    		{
		    	tempArray = tempArray[idArray];
		    	
		    	var index = tempArray.indexOf(idArrayValue);
		    	if (index>=0)
		    	{
		    		index = (index+val+tempArray.size())%tempArray.size();
					return tempArray[index];
		    	}
		    	else if (tempArray.size()>0)
		    	{
					return tempArray[0];
		    	}
		    }		
		}
		
		return 0;
    }
    
	function stringColorEditing(val)
	{
		gfxData[menuElementGfx+3/*string_color*/] = (gfxData[menuElementGfx+3/*string_color*/]-val+65-1/*COLOR_ONE*/)%65 + 1/*COLOR_ONE*/;	// 1 to 65
	}

	function stringGetFont()
	{
		return (gfxData[menuElementGfx+2/*string_font*/]&0xFF);
	}
		
	function stringFontEditing(val)
	{
		gfxData[menuElementGfx+2/*string_font*/] = (stringGetFont()-val+20)%20;	// 0-14 (s,m,l fonts), 15-19 (5 system fonts)
		reloadDynamicResources = true;

		lastFontArray[1] = gfxData[menuElementGfx+2/*string_font*/];
	}

	function iconTypeEditing(val)
	{
//		var eDisplay = gfxData[index+1];
//	    if (eDisplay>=0/*FIELD_SHAPE_CIRCLE*/ && eDisplay<=32/*FIELD_SHAPE_MOUNTAIN*/)

		gfxData[menuElementGfx+1] = (gfxData[menuElementGfx+1]+val+32/*FIELD_SHAPE_MOUNTAIN*/+1)%(32/*FIELD_SHAPE_MOUNTAIN*/+1);
	}

	function iconColorEditing(val)
	{
		gfxData[menuElementGfx+3/*icon_color*/] = (gfxData[menuElementGfx+3/*icon_color*/]-val+65-1/*COLOR_ONE*/)%65 + 1/*COLOR_ONE*/;	// 1 to 65
	}

	function iconGetFont()
	{
		return (gfxData[menuElementGfx+2/*icon_font*/]&0xFF);
	}

	function iconFontEditing(val)
	{
		gfxData[menuElementGfx+2/*icon_font*/] = (iconGetFont()-val+2)%2;
		reloadDynamicResources = true;

		lastFontArray[2] = gfxData[menuElementGfx+2/*icon_font*/];
	}

	function moveBarGetFont()
	{
		return (gfxData[menuElementGfx+2/*movebar_font*/]&0xFF);
	}

	function moveBarFontEditing(val)
	{
		gfxData[menuElementGfx+2/*movebar_font*/] = (moveBarGetFont()-val+2)%2;
		reloadDynamicResources = true;

		lastFontArray[2] = gfxData[menuElementGfx+2/*movebar_font*/];
	}

	function moveBarColorEditing(n, val)
	{
		gfxData[menuElementGfx+3+n] = (gfxData[menuElementGfx+3+n]-val+65-1/*COLOR_ONE*/)%65 + 1/*COLOR_ONE*/;	// 1 to 65
	}

	function moveBarOffColorEditing(val)
	{
		gfxData[menuElementGfx+8] = (gfxData[menuElementGfx+8]-val+66)%66;		// allow for COLOR_NOTSET (-2) so 0 to 65
	}

	function chartTypeEditing(val)
	{
		var axes = (gfxData[menuElementGfx+1]&0x03);
		axes = (axes+val+4)%4;

		gfxData[menuElementGfx+1] &= ~0x03;
		gfxData[menuElementGfx+1] |= (axes&0x03);
	}

	function chartColorEditing(n, val)
	{
		gfxData[menuElementGfx+2+n] = (gfxData[menuElementGfx+2+n]-val+65-1/*COLOR_ONE*/)%65 + 1/*COLOR_ONE*/;	// 1 to 65
	}

	function rectangleGetType()
	{
		return (gfxData[menuFieldGfx+1]&0x3F);
	}

	function rectangleTypeEditing(val)
	{
		var eDisplay = ((gfxData[menuFieldGfx+1]&0x3F) + val + 1)%1;
		gfxData[menuFieldGfx+1] &= ~0x3F; 
		gfxData[menuFieldGfx+1] |= (eDisplay & 0x3F); 
	}
	
	function rectangleGetDirection()
	{
		return ((gfxData[menuFieldGfx+1]&0xC0)>>6); 
	}
	
	function rectangleDirectionEditing(val)
	{
		var temp = (rectangleGetDirection()-val+4)%4;
		gfxData[menuFieldGfx+1] &= ~0xC0; 
		gfxData[menuFieldGfx+1] |= ((temp<<6)&0xC0); 
	}

	function rectangleColorEditing(n, val)
	{
		gfxData[menuFieldGfx+2/*rect_filled*/+n] = (gfxData[menuFieldGfx+2/*rect_filled*/+n]-val+66)%66;	// allow for COLOR_NOTSET (-2) so 0 to 65
	}

	function rectanglePositionGetX()
	{
		return gfxData[menuFieldGfx+4/*rect_x*/];
	}

	function rectanglePositionGetY()
	{
		return gfxData[menuFieldGfx+5/*rect_y*/];
	}

	function rectanglePositionXEditing(val)
	{
		gfxData[menuFieldGfx+4/*rect_x*/] = getMinMax(gfxData[menuFieldGfx+4/*rect_x*/]-val, 0, displaySize);
	}

	function rectanglePositionYEditing(val)
	{
		gfxData[menuFieldGfx+5/*rect_y*/] = getMinMax(gfxData[menuFieldGfx+5/*rect_y*/]-val, 0, displaySize);
	}

	function rectanglePositionCentreX()
	{
		gfxData[menuFieldGfx+4/*rect_x*/] = displayHalf;
	}

	function rectanglePositionCentreY()
	{
		gfxData[menuFieldGfx+5/*rect_y*/] = displayHalf;
	}

	function rectangleGetWidth()
	{
		return gfxData[menuFieldGfx+6/*rect_w*/];
	}

	function rectangleWidthEditing(val)
	{
		gfxData[menuFieldGfx+6/*rect_w*/] = getMinMax(gfxData[menuFieldGfx+6/*rect_w*/]-val, 1, displaySize);
	}

	function rectangleGetHeight()
	{
		return gfxData[menuFieldGfx+7/*rect_h*/];
	}

	function rectangleHeightEditing(val)
	{
		gfxData[menuFieldGfx+7/*rect_h*/] = getMinMax(gfxData[menuFieldGfx+7/*rect_h*/]-val, 1, displaySize);
	}

	function ringGetTypeFromGfxIndex(index)
	{
		return (gfxData[index+1]&0x3F);
	}

	function ringGetType()
	{
		return (gfxData[menuFieldGfx+1]&0x3F);
	}

	function ringTypeEditing(val)
	{
		var eDisplay = ((gfxData[menuFieldGfx+1]&0x3F) + val + 13)%13;
		gfxData[menuFieldGfx+1] &= ~0x3F; 
		gfxData[menuFieldGfx+1] |= (eDisplay & 0x3F); 
	}
	
	function ringGetDirectionAnti()
	{
		return ((gfxData[menuFieldGfx+1]&0x40)!=0); 
	}
	
	function ringDirectionEditing()
	{
		gfxData[menuFieldGfx+1] ^= 0x40;
		
		// swap start and end over too
		var temp = gfxData[menuFieldGfx+3];
		gfxData[menuFieldGfx+3] = gfxData[menuFieldGfx+4];
		gfxData[menuFieldGfx+4] = temp;
	}
	
	function ringGetLimit100()
	{
		return ((gfxData[menuFieldGfx+1]&0x80)!=0); 
	}
	
	function ringLimitEditing()
	{
		gfxData[menuFieldGfx+1] ^= 0x80;
	}
	
	function ringGetFont()
	{
		return (gfxData[menuFieldGfx+2/*ring_font*/]&0xFF);
	}
	
	function ringFontEditing(val)
	{
		gfxData[menuFieldGfx+2/*ring_font*/] = (ringGetFont() - val + 25/*SECONDFONT_UNUSED*/)%25/*SECONDFONT_UNUSED*/; 
		reloadDynamicResources = true;
	}
	
	function ringStartEditing(val)
	{
		gfxData[menuFieldGfx+3] = (gfxData[menuFieldGfx+3]-val+60)%60;
	}
	
	function ringEndEditing(val)
	{
		gfxData[menuFieldGfx+4] = (gfxData[menuFieldGfx+4]-val+60)%60;
	}
	
	function ringColorEditing(n, val)
	{
		gfxData[menuFieldGfx+5+n] = (gfxData[menuFieldGfx+5+n]-val+66)%66;		// allow for COLOR_NOTSET (-2) so 0 to 65
	}
	
	function secondsGetFont()
	{
		return (gfxData[menuFieldGfx+1]&0xFF);
	}
	
	function secondsFontEditing(val)
	{
		var temp = (secondsGetFont()-val+25/*SECONDFONT_UNUSED*/)%25/*SECONDFONT_UNUSED*/;
		
		gfxData[menuFieldGfx+1] &= ~0x00FF; 
		gfxData[menuFieldGfx+1] |= temp;
		reloadDynamicResources = true;
	}

	function secondsGetRefresh()
	{
		return ((gfxData[menuFieldGfx+1]>>8) & 0xFF);
	}
	
	function secondsRefreshEditing(val)
	{
		var temp = (secondsGetRefresh() - val + 3)%3;
		
		gfxData[menuFieldGfx+1] &= ~0xFF00;
		gfxData[menuFieldGfx+1] |= (temp<<8); 
		reloadDynamicResources = true;
	}
	
	function secondsColorEditing(n, val)
	{
		if (n==0)	/* base color */
		{
			gfxData[menuFieldGfx+2] = (gfxData[menuFieldGfx+2]-val+65-1/*COLOR_ONE*/)%65 + 1/*COLOR_ONE*/;	// 1 to 65
		}
		else		/* optional override colors */
		{
			gfxData[menuFieldGfx+2+n] = (gfxData[menuFieldGfx+2+n]-val+66)%66;		// 0 to 65
		}

		buildSecondsColorArray(menuFieldGfx);
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
    
    // up=0 down=1 left=2 right=3
    function hasDirection(d)
    {
    	return false;
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
	var doExit = false;
	
    function initialize()
    {   	
    	myMenuItem.initialize();
    }
    
    function getString()
    {
    	return "back to exit";
    }
    
    // up=0 down=1 left=2 right=3
    function hasDirection(d)
    {
    	return (d==3);
    }

    function exitApp()
    {
    	return doExit;
    }

    function onSelect()
    {
		return new myMenuItemFieldSelect();
    }
    
    function onBack()
    {
    	var ret = new myMenuItemExitApp();
    	ret.doExit = true;
    	return ret;
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
    	return editorView.getGfxName(editorView.menuFieldGfx);
    }
    
    // up=0 down=1 left=2 right=3
    function hasDirection(d)
    {
    	return (d!=0 || editorView.prevGfxField(editorView.menuFieldGfx)>=0);
    }

    function onNext()
    {
		var nextIndex = editorView.nextGfxField(editorView.menuFieldGfx);
		if (nextIndex>=0)
		{
			editorView.menuFieldGfx = nextIndex;
		}
    	else
    	{
    		return new myMenuItemFieldAdd();
    	}
    	return null;
    }
    
    function onPrevious()
    {
    	var prevIndex = editorView.prevGfxField(editorView.menuFieldGfx);
    	if (prevIndex>=0)
    	{
    		editorView.menuFieldGfx = prevIndex;
    	}
    	return null;
    }
    
    function onSelect()
    {
		var id = editorView.getGfxId(editorView.menuFieldGfx);
		if (id==0)		// header
		{
			return new myMenuItemHeader();
		}
		else if (id==1)		// field
		{
			return new myMenuItemFieldEdit();
		}
		else if (id==7)		// rectangle
		{
			return new myMenuItemRectangle();
		}
		else if (id==8)	// ring
		{
			return new myMenuItemRing();
		}
		else if (id==9)	// seconds
		{
			return new myMenuItemSeconds();
		}
			
		return null;
    }
    
    function onBack()
    {
    	return new myMenuItemExitApp();
    }
}

(:m2app)
class myMenuItemFieldAdd extends myMenuItem
{
//	enum
//	{
//		s_top,
//		s_addHorizontal,
//		s_addFree,
//		s_addRectangle,
//		s_addRing,
//		s_addSeconds,
//	}

	var fState;

    function initialize()
    {
    	myMenuItem.initialize();

    	fState = 0;
    }
    
    function getString()
    {
    	return editorView.safeStringFromJsonData(Rez.JsonData.id_fieldAddStrings, -1, fState);
    }

    // up=0 down=1 left=2 right=3
    function hasDirection(d)
    {
    	return true;
    }

	function onEditing(val)
	{
		if (fState==0/*s_top*/)
		{
			if (val>0)
			{
				return new myMenuItemQuickAdd();
			}
			else
			{
				// set menuFieldGfx to the last field
				for (editorView.menuFieldGfx = 0; ;)
				{
					var nextIndex = editorView.nextGfxField(editorView.menuFieldGfx);
					if (nextIndex<0)
					{
						break;
					}
					editorView.menuFieldGfx = nextIndex;
				}

				return new myMenuItemFieldSelect();
			}
		}
		else
		{
			fState = (fState+val-1+4)%4 + 1;
		}

		return null;
	}
    
    function onNext()
    {
		return onEditing(1);
    }
    
    function onPrevious()
    {
		return onEditing(-1);
    }
    
    function onSelect()
    {   	
		if (fState==0/*s_top*/)
		{
			fState = 1/*s_addHorizontal*/;
		}
		else
		{
			var fArray = [
				editorView.method(:gfxAddField),
				editorView.method(:gfxAddRectangle),
				editorView.method(:gfxAddRing),
				editorView.method(:gfxAddSeconds),
			];
    		
    		var index = fArray[fState-1].invoke(editorView.gfxNum);
	
//			if (fState==1/*s_addHorizontal*/)
//			{
//				index = editorView.gfxAddField(editorView.gfxNum);
//			}
//			else if (fState==2/*s_addFree*/)
//			{
//				index = editorView.gfxAddField(editorView.gfxNum);
//			}
//			else if (fState==3/*s_addRectangle*/)
//			{
//				index = editorView.gfxAddRectangle(editorView.gfxNum);
//			}
//			else if (fState==4/*s_addRing*/)
//			{
//				index = editorView.gfxAddRing(editorView.gfxNum);
//			}
//			else if (fState==5/*s_addSeconds*/)
//			{
//				index = editorView.gfxAddSeconds(editorView.gfxNum);
//			}

	    	if (index>=0)
	    	{
	    		editorView.menuFieldGfx = index;
	    		return new myMenuItemFieldSelect();
	    	}
		}
		
    	return null;
    }
    
    function onBack()
    {
		if (fState!=0/*s_top*/)
		{
			fState = 0/*s_top*/;
			return null;
		}
		else
		{
    		return new myMenuItemExitApp();
    	}
    }
}

(:m2app)
class myMenuItemQuickAdd extends myMenuItem
{
	//time
	//time with colon
	//date
	//steps (text)
	//steps (ring)
	//heart rate (text)
	//battery indicator
	//alarm icon
	//seconds indicator
	//digital seconds
	//horizontal line
	//vertical line

    function initialize()
    {
    	myMenuItem.initialize();
    }
    
    function getString()
    {
    	return "quick add";
    }
    
    // up=0 down=1 left=2 right=3
    function hasDirection(d)
    {
    	return true;
    }

    function onNext()
    {
   		return new myMenuItemSaveLoadProfile(0);
    }
    
    function onPrevious()
    {
   		return new myMenuItemFieldAdd();
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
class myMenuItemSaveLoadProfile extends myMenuItem
{
	var type;	// 0==save, 1==load, 2==load preset

	var min;
	var max;

	var editing = false;
	var profileIndex = 0;

    function initialize(t)
    {
    	myMenuItem.initialize();
    	
    	type = t;
    	
    	if (type==2)
    	{
    		min = editorView.PROFILE_NUM_USER;
    		max = editorView.PROFILE_NUM_USER + editorView.PROFILE_NUM_PRESET - 1;
    	}
    	else
    	{
    		min = 0;
    		max = editorView.PROFILE_NUM_USER - 1;
    	}
    	
    	profileIndex = min;
    }
    
    function getString()
    {
    	if (editing)
    	{
    		if (type!=2)
    		{
    			return "" + (profileIndex+1);
    		}
    		else
    		{
    			return "" + (profileIndex+1) + ". " + editorView.getPresetProfileString(profileIndex, 0);
    		}
    	}
		else
		{
    		//return ["save profile", "load profile", "load preset"][type];
    		return editorView.safeStringFromJsonData(Rez.JsonData.id_saveLoadStrings, -1, type);
    	}
    }
    
    // up=0 down=1 left=2 right=3
    function hasDirection(d)
    {
    	return true;
    }

    function onNext()
    {
    	if (editing)
    	{
   			profileIndex++;
    		if (profileIndex > max)
    		{
    			profileIndex = min;
    		}
    		
    		return null;
    	}
		else
		{
			if (type<2)
			{
   				return new myMenuItemSaveLoadProfile(type+1);
   			}
   			else
   			{
   				return new myMenuItemReset();
   			}
   		}
    }
    
    function onPrevious()
    {
    	if (editing)
    	{
    		profileIndex--;
    		if (profileIndex < min)
    		{
    			profileIndex = max;
    		}

    		return null;
    	}
    	else
    	{
			if (type>0)
			{
   				return new myMenuItemSaveLoadProfile(type-1);
   			}
   			else
   			{
   				return new myMenuItemQuickAdd();
   			}
   		}
    }
    
    function onSelect()
    {
    	if (editing)
    	{
    		if (type==0)
    		{
    			editorView.saveProfile(profileIndex);
				
				editorView.profileActive = profileIndex;		// set the active profile number
				applicationProperties.setValue("PN", profileIndex+1);		// set the profile number
    		}
    		else
    		{
				editorView.appWantsToLoadProfile = profileIndex;
    		}
    	}
    	else
    	{
    		editing = true;
    	}
    	
    	return null;
    }
    
    function onBack()
    {
    	if (editing)
    	{
    		editing = false;
    		return null;
    	}
    	else
    	{
    		return new myMenuItemExitApp();
    	}
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
    	return "clear display";
    }
    
    // up=0 down=1 left=2 right=3
    function hasDirection(d)
    {
    	return (d!=1);
    }

    function onNext()
    {
    	return null;
    }
    
    function onPrevious()
    {
   		return new myMenuItemSaveLoadProfile(2);
    }
    
    function onSelect()
    {
    	editorView.fieldDeleteAll();
    	
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
//gfxData[0+9] = getMinMax(gfxData[0+9], 0, 1);		// propKerningOn

//	enum
//	{
//		f_background,		0
//		f_foreground,		1
//		f_menuColor,		2
//		f_menuBorder,		3
//		f_fieldHighlight,	4
//		f_ElementHighlight,	5
//		f_batteryHigh,		6
//		f_batteryLow,		7
//		f_2ndTime,			8
//		f_moveBarAlert,		9
//		f_fontSystemCase,	10
//		f_fontUnsupported,	11
//		f_memoryDisplay,	12
//		f_menuhide,			13
//
//		f_backgroundEdit,		100
//		f_foregroundEdit,		101
//		f_menuColorEdit,		102
//		f_menuBorderEdit,		103
//		f_fieldHighlightEdit,	104
//		f_ElementHighlightEdit,	105
//		f_batteryHighEdit,		106
//		f_batteryLowEdit,		107
//		f_2ndTimeEdit,			108
//		f_moveBarAlertEdit,		109
//		f_fontSystemCaseEdit,	110
//		f_fontUnsupportedEdit,	111
//		f_memoryDisplayEdit,	112
//		f_menuHideEdit,			113
//	}

	var fState;

    function initialize()
    {
    	myMenuItem.initialize();

    	fState = 0;
    }
    
    function getString()
    {
    	if (fState==106/*f_batteryHighEdit*/)
    	{
    		return "" + editorView.propBatteryHighPercentage;
    	}
    	else if (fState==107/*f_batteryLowEdit*/)
    	{
    		return "" + editorView.propBatteryLowPercentage;
    	}
    	else if (fState==108/*f_2ndTimeEdit*/)
    	{
    		return "" + editorView.prop2ndTimeZoneOffset;
    	}
    	else if (fState==109/*f_moveBarAlertEdit*/)
    	{
    		return "" + editorView.propMoveBarAlertTriggerLevel;
    	}
    	else if (fState==110/*f_fontSystemCaseEdit*/)
    	{
    		return editorView.safeStringFromJsonData(Rez.JsonData.id_headerStrings2, 0, editorView.propFieldFontSystemCase);
    	}
    	else if (fState==111/*f_fontUnsupportedEdit*/)
    	{
    		return editorView.safeStringFromJsonData(Rez.JsonData.id_headerStrings2, 1, editorView.propFieldFontUnsupported);
    	}
    	else if (fState==112/*f_memoryDisplayEdit*/)
    	{
    		return editorView.safeStringFromJsonData(Rez.JsonData.id_headerStrings2, 2, editorView.memoryDisplayMode);
    	}
    	else if (fState<100/*f_backgroundEdit*/)
    	{
    		return editorView.safeStringFromJsonData(Rez.JsonData.id_headerStrings, -1, fState);
    	}
    	//else
    	//{
    	//	return "editing...";
    	//}

   		return null;
    }
    
    // up=0 down=1 left=2 right=3
    function hasDirection(d)
    {
    	if (d==3)	// right
    	{
    	 	if (fState>=100/*f_backgroundEdit*/)
    	 	{
    			return false;
    		}
    	}
    	else if (d==0)	// up
    	{
	    	if (fState==106/*f_batteryHighEdit*/)
	    	{
			    return !editorView.headerBatteryAtMax(0);
	    	}
	    	else if (fState==107/*f_batteryLowEdit*/)
	    	{
			    return !editorView.headerBatteryAtMax(1);
	    	}
	    	else if (fState==108/*f_2ndTimeEdit*/)
	    	{
			    return !editorView.header2ndTimeZoneAtMax();
	    	}
	    	else if (fState==109/*f_moveBarAlertEdit*/)
	    	{
			    return !editorView.headerMoveBarAlertAtMax();
	    	}
    	}
    	else if (d==1)	// down
    	{
	    	if (fState==106/*f_batteryHighEdit*/)
	    	{
			    return !editorView.headerBatteryAtMin(0);
	    	}
	    	else if (fState==107/*f_batteryLowEdit*/)
	    	{
			    return !editorView.headerBatteryAtMin(1);
	    	}
	    	else if (fState==108/*f_2ndTimeEdit*/)
	    	{
			    return !editorView.header2ndTimeZoneAtMin();
	    	}
	    	else if (fState==109/*f_moveBarAlertEdit*/)
	    	{
			    return !editorView.headerMoveBarAlertAtMin();
	    	}
    	}

    	return true;
    }

    function onEditing(val)
    {
		if (fState<100/*f_backgroundEdit*/)
		{
			fState = (fState+val+14)%14;
		}
    	else if (fState==100/*f_backgroundEdit*/)
    	{
    		editorView.headerBackgroundColorEditing(val);
    	}
    	else if (fState==101/*f_foregroundEdit*/)
    	{
    		editorView.headerForegroundColorEditing(val);
    	}
    	else if (fState==102/*f_menuColorEdit*/)
    	{
    		editorView.headerMenuColorEditing(val);
    	}
    	else if (fState==103/*f_menuBorderEdit*/)
    	{
    		editorView.headerMenuBorderColorEditing(val);
    	}
    	else if (fState==104/*f_fieldHighlightEdit*/)
    	{
    		editorView.headerFieldHighlightColorEditing(val);
    	}
    	else if (fState==105/*f_ElementHighlightEdit*/)
    	{
    		editorView.headerElementHighlightColorEditing(val);
    	}
    	else if (fState==106/*f_batteryHighEdit*/)
    	{
    		editorView.headerBatteryEditing(0, val);
    	}
    	else if (fState==107/*f_batteryLowEdit*/)
    	{
    		editorView.headerBatteryEditing(1, val);
    	}
    	else if (fState==108/*f_2ndTimeEdit*/)
    	{
    		editorView.header2ndTimeZoneEditing(val);
    	}
    	else if (fState==109/*f_moveBarAlertEdit*/)
    	{
    		editorView.headerMoveBarAlertEditing(val);
    	}
    	else if (fState==110/*f_fontSystemCaseEdit*/)
    	{
    		editorView.headerFontSystemCaseEditing(val);
    	}
    	else if (fState==111/*f_fontUnsupportedEdit*/)
    	{
    		editorView.headerFontUnsupportedEditing(val);
    	}
    	else if (fState==112/*f_memoryDisplayEdit*/)
    	{
    		editorView.memoryDisplayMode = (editorView.memoryDisplayMode + val + 3)%3;
    	}
    	else if (fState==113/*f_menuHideEdit*/)
    	{
			editorView.menuHide = false;
			fState -= 100;
    	}
    	
    	return null;
    }
    
    function onNext()
    {
   		return onEditing(1);
    }
    
    function onPrevious()
    {
   		return onEditing(-1);
    }
    
    function onSelect()
    {
		if (fState<100)
		{
			if (fState>=0/*f_background*/ && fState<=5/*f_ElementHighlight*/)
			{
				editorView.startColorEditing(editorView.menuFieldGfx+3+fState);
			}
	    	else if (fState==13/*f_menuHide*/)
	    	{
				editorView.menuHide = true;
			}
		
			fState += 100;
		}
    	else if (fState==113/*f_menuHideEdit*/)
    	{
			editorView.menuHide = false;
			fState -= 100;
    	}
    	
    	return null;
    }
    
    function onBack()
    {
    	if (fState<100)
    	{    
   			return new myMenuItemFieldSelect();
   		}
   		else
   		{   		
   			//if (fState==9/*f_backgroundEdit*/)
   			//{
				editorView.endColorEditing();
   			//}
	    	//else if (fState==17/*f_menuHideEdit*/)
	    	//{
				editorView.menuHide = false;
			//}

   			fState -= 100;
   		}

   		return null;
    }
}

(:m2app)
class myMenuItemFieldEdit extends myMenuItem
{
//	enum
//	{
//		f_elements,
//		f_position,
//		f_align,
//		f_vis,
//		f_earlier,
//		f_later,
//		f_delete,
//
//		f_x,
//		f_y,
//		f_xCentre,
//		f_yCentre,
//		f_tap,
//
//		f_xEdit,
//		f_yEdit,
//		f_alignEdit,
//		f_visEdit,
//	}

	var fState;

    function initialize()
    {
    	myMenuItem.initialize();

    	fState = 0;

		editorView.menuElementGfx = 0;	// clear any selected element
    }
    
    function getString()
    {
		if (fState==12/*f_xEdit*/)
    	{
    		return "x=" + editorView.fieldPositionGetX();
    	}
		else if (fState==13/*f_yEdit*/)
    	{
    		return "y=" + editorView.fieldPositionGetY();
    	}
    	else if (fState==14/*f_alignEdit*/)
    	{
    		return editorView.safeStringFromJsonData(Rez.JsonData.id_fieldEditStrings, 1, editorView.fieldGetAlignment());
    	}
    	else if (fState==15/*f_visEdit*/)
    	{
    		return editorView.fieldVisibilityString();
    	}
    	else if (fState<=11/*f_tap*/)
    	{
    		return editorView.safeStringFromJsonData(Rez.JsonData.id_fieldEditStrings, 0, fState);
    	}
    	else
    	{
    		return "editing...";	// for x & y position
    	}
    }
    
    // up=0 down=1 left=2 right=3
    function hasDirection(d)
    {
    	return (d!=3 || fState<11/*f_tap*/);
    }

    function onEditing(val)
    {
		if (fState<=6/*r_delete*/)
    	{
    		fState = (fState+val+7)%7;
    	}
		else if (fState<=11/*f_tap*/)
    	{
    		//fState = (fState+val+5-7)%5 + 7;
    		fState = (fState+val+4-7)%4 + 7;		// removed tap for now
    	}
		else if (fState==12/*f_xEdit*/)
    	{
    		editorView.fieldPositionXEditing(val);
    	}
		else if (fState==13/*f_yEdit*/)
    	{
    		editorView.fieldPositionYEditing(val);
    	}
		else if (fState==14/*f_alignEdit*/)
    	{
    		editorView.fieldAlignmentEditing(val);
    	}
		else if (fState==15/*f_visEdit*/)
    	{
    		editorView.fieldVisibilityEditing(val);
    	}

   		return null;
    }
    
    function onNext()
    {
   		return onEditing(1);
    }
    
    function onPrevious()
    {
   		return onEditing(-1);
    }
    
    function onSelect()
    {
		if (fState==0/*f_elements*/)
		{
			var nextIndex = editorView.nextGfx(editorView.menuFieldGfx);
			if (nextIndex>=0 && nextIndex<editorView.afterGfxField(editorView.menuFieldGfx))
			{
				editorView.menuElementGfx = nextIndex;
				return new myMenuItemElementSelect();
			}
			else
			{
				return new myMenuItemElementAdd();
			}
		}
		else if (fState==1/*f_position*/)
		{
			fState = 7/*f_x*/;
		}
		else if (fState==2/*f_align*/)
		{
			fState = 14/*f_alignEdit*/;
		}
		else if (fState==3/*f_vis*/)
		{
			fState = 15/*f_visEdit*/;
		}
		else if (fState==4/*f_earlier*/)
		{
			editorView.fieldEarlier();
		}
		else if (fState==5/*f_later*/)
		{
			editorView.fieldLater();
		}
		else if (fState==6/*f_delete*/)
		{
			editorView.fieldDelete();
			return new myMenuItemFieldSelect();
		}
		else if (fState==7/*f_x*/)
		{
			fState = 12/*f_xEdit*/;
		}
		else if (fState==8/*f_y*/)
		{
			fState = 13/*f_yEdit*/;
		}
		else if (fState==9/*f_xCentre*/)
		{
			editorView.fieldPositionCentreX();
		}
		else if (fState==10/*f_yCentre*/)
		{
			editorView.fieldPositionCentreY();
		}

    	return null;
    }
    
    function onBack()
    {
		if (fState<=6/*f_delete*/)
		{
			return new myMenuItemFieldSelect();
		}
		else if (fState<=11/*f_tap*/)
		{
			fState = 1/*f_position*/;
		}
		else if (fState==12/*f_xEdit*/)
		{
			fState = 7/*f_x*/;
		}
		else if (fState==13/*f_yEdit*/)
		{
			fState = 8/*f_y*/;
		}
		else if (fState==14/*f_alignEdit*/)
		{
			fState = 2/*f_align*/;
		}
		else if (fState==15/*f_visEdit*/)
		{
			fState = 3/*f_vis*/;
		}

   		return null;
    }
}

(:m2app)
class myMenuItemElementSelect extends myMenuItem
{
	//select element
	//	color
	//		next
	//		previous
	//		tap
	//	font
	//	visibility
	//	delete element
	//add element
	//	type (largehour, largeminute, largecolon, string, icon, movebar, chart)
	
    function initialize()
    {   	
    	myMenuItem.initialize();
    }
    
    function getString()
    {
    	return editorView.getGfxName(editorView.menuElementGfx);
    }
    
    // up=0 down=1 left=2 right=3
    function hasDirection(d)
    {
    	return (d!=0 || editorView.prevGfx(editorView.menuElementGfx)>editorView.menuFieldGfx);
    }

    function onNext()
    {
		var nextIndex = editorView.nextGfx(editorView.menuElementGfx);
		if (nextIndex>=0 && nextIndex<editorView.afterGfxField(editorView.menuFieldGfx))
		{
			editorView.menuElementGfx = nextIndex;
		}
    	else
    	{
    		return new myMenuItemElementAdd();
    	}
    	return null;
    }
    
    function onPrevious()
    {
    	var prevIndex = editorView.prevGfx(editorView.menuElementGfx);
    	if (prevIndex>=0 && prevIndex>editorView.menuFieldGfx)
    	{
    		editorView.menuElementGfx = prevIndex;
    	}
    	return null;
    }
    
    function onSelect()
    {
    	var id = editorView.getGfxId(editorView.menuElementGfx);

		if (id>=2 &&		// large (hour, minute, colon)
			//case 3:		// string
			//case 4:		// icon
			//case 5:		// movebar
			id<=6)		// chart
		{
				return new myMenuItemElementEdit(id);
		}

		return null;
    }
    
    function onBack()
    {
    	return new myMenuItemFieldEdit();
    }
}

(:m2app)
class myMenuItemElementEdit extends myMenuItem
{
//	enum
//	{
//		f_font,
//		f_color,

//		f_visibility,
//		f_earlier,
//		f_later,
//		f_delete,
//
//		f_fontEdit,
//		f_colorEdit,
//	}

// large hour, minute, colon
//		gfxData[index+1] = 0/*APPFONT_ULTRA_LIGHT*/;	// font
//		gfxData[index+2] = 3+2;	// color

// string
//		gfxData[index+1] = dataType;		// type
//		gfxData[index+2] = 15/*APPFONT_REGULAR_SMALL*/;	// font & diacritics
//		gfxData[index+3] = 3+2;	// color

// icon
//		gfxData[index+1] = 0;	// type
//		gfxData[index+2] = 0;	// font
//		gfxData[index+3] = 3+2;	// color

// move bar
//		gfxData[index+1] = 0;	// type
//		gfxData[index+2] = 0;	// font
//		gfxData[index+3] = 3+2;	// color 1
//		gfxData[index+4] = 3+2;	// color 2
//		gfxData[index+5] = 3+2;	// color 3
//		gfxData[index+6] = 3+2;	// color 4
//		gfxData[index+7] = 3+2;	// color 5
//		gfxData[index+8] = COLOR_NOTSET+2;	// color off

// chart
//		gfxData[index+1] = 0;	// type
//		gfxData[index+2] = 3+2;	// color chart
//		gfxData[index+3] = 3+2;	// color axes

	var fId;

	var fState;

	var fStringsIndex;
	var fNumCustom;

	var idArray;
	var idArrayValue;

    function initialize(id)
    {
    	myMenuItem.initialize();
    	
    	fState = 0;
    	fId = id;
    	
    	if (fId==2)	// large (hour, minute, colon)
    	{
    		fStringsIndex = 0;
    		fNumCustom = 3;
    	}
    	else if (fId==3)	// string
    	{
    		fStringsIndex = 1;
    		fNumCustom = 3;
    	}
    	else if (fId==4)	// icon
    	{
    		fStringsIndex = 2;
    		fNumCustom = 3;
    	}
    	else if (fId==5)	// movebar
    	{
    		fStringsIndex = 3;
    		fNumCustom = 7;
    	}
    	else if (fId==6)	// chart
    	{
    		fStringsIndex = 4;
    		fNumCustom = 3;
    	}
    	
    	idArray = -1;
    	idArrayValue = -1;
    }
    
    function getString()
    {
		var numTop = fNumCustom+4;

    	if (fState==numTop+fNumCustom)
    	{
    		return editorView.elementVisibilityString();
    	}
    	else if (fState<numTop)
    	{
    		return editorView.safeStringFromJsonData(Rez.JsonData.id_editElementStrings, fStringsIndex, fState);
    	}
		else if (fId==2 && fState==numTop)	// large type
		{
			return editorView.getLargeTypeName(editorView.largeGetType());
	    }
		else if (fId==2 && fState==numTop+1)	// large font
		{
			return editorView.safeStringFromJsonDataMulti(Rez.JsonData.id_editElementLargeFontStrings, Rez.JsonData.id_editElementLargeFontStrings2, null, editorView.largeGetFont());
	    }
		else if (fId==3 && fState==numTop)	// string type
		{
			if (idArrayValue<0)
			{
    			return editorView.safeStringFromJsonData(Rez.JsonData.id_editElementStrings3, 2, idArray);
			}
			else
			{
				return editorView.getStringTypeName(idArrayValue);
			}
	    }
		else if (fId==3 && fState==numTop+1)	// string font
		{
    		return editorView.safeStringFromJsonData(Rez.JsonData.id_editElementStrings2, -1, editorView.stringGetFont());
	    }
		else if (fId==4 && fState==numTop+1)	// icon
		{
    		return editorView.safeStringFromJsonData(Rez.JsonData.id_editElementStrings3, 0, editorView.iconGetFont());
	    }
		else if (fId==5 && fState==numTop)	// movebar
		{
    		return editorView.safeStringFromJsonData(Rez.JsonData.id_editElementStrings3, 1, editorView.moveBarGetFont());
	    }
    	else
    	{
    		return "editing...";
    	}
    }
    
    // up=0 down=1 left=2 right=3
    function hasDirection(d)
    {
    	return (d!=3 || fState<(fNumCustom+4) || ((fId==2 || fId==3) && fState==(fNumCustom+4)));
    }

    function onEditing(val)
    {
		var numTop = fNumCustom+4;

    	if (fState<numTop)
    	{
    		fState = (fState+val+numTop)%numTop;
    	}
    	else if (fState==numTop+fNumCustom)
    	{
    		editorView.elementVisibilityEditing(val);
    	}
    	else
    	{
    		if (fId==2)	// large (hour, minute, colon)
    		{
		    	if (fState==numTop)
		    	{
	    			editorView.largeTypeEditing(val);
		    	}
		    	else if (fState==numTop+1)
		    	{
	    			editorView.largeFontEditing(val);
		    	}
		    	else if (fState==numTop+2)
		    	{
		    		editorView.largeColorEditing(val);
		    	}
		    }
    		else if (fId==3)	// string
    		{
		    	if (fState==numTop)
		    	{
		    		if (idArrayValue<0)
		    		{
		    			idArray = (idArray+val+5)%5;
		    		}
		    		else
		    		{
			    		idArrayValue = editorView.stringTypeEditing(val, idArray, idArrayValue);
			    		editorView.stringSetType(idArrayValue);
		    		}
		    	}
		    	else if (fState==numTop+1)
		    	{
	    			editorView.stringFontEditing(val);
		    	}
		    	else if (fState==numTop+2)
		    	{
		    		editorView.stringColorEditing(val);
		    	}
		    }
    		else if (fId==4)	// icon
    		{
		    	if (fState==numTop)
		    	{
	    			editorView.iconTypeEditing(val);
		    	}
		    	else if (fState==numTop+1)
		    	{
	    			editorView.iconFontEditing(val);
		    	}
		    	else if (fState==numTop+2)
		    	{
		    		editorView.iconColorEditing(val);
		    	}
		    }
    		else if (fId==5)	// movebar
    		{
		    	if (fState==numTop)
		    	{
		    		editorView.moveBarFontEditing(val);
		    	}
		    	else if (fState<numTop+6)
		    	{
		    		editorView.moveBarColorEditing(fState-(numTop+1), val);
		    	}
		    	else if (fState==numTop+6)
		    	{
		    		editorView.moveBarOffColorEditing(val);
		    	}
		    }
    		else if (fId==6)	// chart
    		{
		    	if (fState==numTop)
		    	{
		    		editorView.chartTypeEditing(val);
		    	}
		    	else if (fState<=numTop+2)
		    	{
		    		editorView.chartColorEditing(fState-(numTop+1), val);
		    	}
		    }
		}
		    
   		return null;
    }
    
    function onNext()
    {
    	return onEditing(1);
    }
    
    function onPrevious()
    {
    	return onEditing(-1);
    }
    
    function onSelect()
    {
		var numTop = fNumCustom+4;

    	if (fState<(fNumCustom+1))
    	{
			fState += numTop;

    		if (fId==2)	// large (hour, minute, colon)
    		{
		    	if (fState==numTop+2)
		    	{
		    		editorView.startColorEditing(editorView.menuElementGfx+3/*large_color*/);
		    	}
		    }
    		else if (fId==3)	// string
    		{
    			if (fState==numTop)
    			{
    				if (idArray<0)
    				{
		    			idArray = 0;
			    		idArrayValue = -1;
			    	}
    			}
		    	else if (fState==numTop+2)
		    	{
		    		editorView.startColorEditing(editorView.menuElementGfx+3/*string_color*/);
		    	}
		    }
    		else if (fId==4)	// icon
    		{
		    	if (fState==numTop+2)
		    	{
		    		editorView.startColorEditing(editorView.menuElementGfx+3/*icon_color*/);
		    	}
		    }
    		else if (fId==5)	// movebar
    		{
		    	if (fState>numTop && fState<=numTop+6)
		    	{
		    		editorView.startColorEditing(editorView.menuElementGfx+3+fState-(numTop+1));
		    	}
		    }
    		else if (fId==6)	// chart
    		{
		    	if (fState>numTop && fState<=numTop+2)
		    	{
		    		editorView.startColorEditing(editorView.menuElementGfx+2+fState-(numTop+1));
		    	}
		    }
    	}
    	else if (fState==(fNumCustom+1))
    	{
			editorView.elementEarlier();
    	}
    	else if (fState==(fNumCustom+2))
    	{
    		editorView.elementLater();
    	}
    	else if (fState==(fNumCustom+3))
    	{
			editorView.elementDelete();
			if (editorView.menuElementGfx>editorView.menuFieldGfx && editorView.menuElementGfx<editorView.afterGfxField(editorView.menuFieldGfx))
			{
				return new myMenuItemElementSelect();
			}
			else
			{
				return new myMenuItemElementAdd();
			}
    	}
		else if (fState==numTop)
		{
    		if (fId==2)	// large (hour, minute, colon)
    		{
				return onBack();	// selected by user so go back
		    }
    		else if (fId==3)	// string
    		{
    			if (idArrayValue<0)
    			{
	    			idArrayValue = editorView.stringTypeEditing(0, idArray, editorView.stringGetType());	// set initial value
	    			editorView.stringSetType(idArrayValue);
	    		}
	    		else
	    		{
	    			// selected by user so go back (twice)
	    			onBack();
	    			return onBack();
	    		}
			}
    	}
    	
    	return null;
    }
    
    function onBack()
    {
		var numTop = fNumCustom+4;

    	if (fState<numTop)
    	{
			return new myMenuItemElementSelect();
    	}
    	else
    	{
			if (fState==numTop)
			{
	    		if (fId==3)	// string
	    		{
	    			if (idArrayValue>=0)
	    			{
		    			idArrayValue = -1;
   						return null;		// keep fState==numTop
	    			}
	    			else
	    			{
	    				idArray = -1;
	    			}
				}
			}
						
    		editorView.endColorEditing();

			fState -= numTop;
    	}

   		return null;
    }
}

(:m2app)
class myMenuItemElementAdd extends myMenuItem
{
//	var timeIds = [
//		1/*FIELD_HOUR*/,			// hour
//		2/*FIELD_MINUTE*/,			// minute
//		26/*FIELD_SEPARATOR_COLON*/,
//		19/*FIELD_AM*/ | 0x80,
//		20/*FIELD_PM*/ | 0x80,
//		21/*FIELD_A*/ | 0x80,
//		22/*FIELD_P*/ | 0x80,
//		47/*FIELD_2ND_HOUR*/,
//		41/*FIELD_SUNRISE_HOUR*/,
//		42/*FIELD_SUNRISE_MINUTE*/,
//		43/*FIELD_SUNSET_HOUR*/,
//		44/*FIELD_SUNSET_MINUTE*/,
//		45/*FIELD_SUNEVENT_HOUR*/,
//		46/*FIELD_SUNEVENT_MINUTE*/,
//	]b;
//	
//	var separatorIds = [
//		23/*FIELD_SEPARATOR_SPACE*/,		// space
//		24,									// forward slash
//		25,									// back slash
//		26/*FIELD_SEPARATOR_COLON*/,		// colon
//		27,									// minus
//		28,									// full stop
//		29,									// comma
//		30/*FIELD_SEPARATOR_PERCENT*/,		// percent
//	]b;
//	
//	var dateIds = [
//		3/*FIELD_DAY_NAME*/ | 0x80,		// day name
//		9/*FIELD_MONTH_NAME*/ | 0x80,		// month name
//		4/*FIELD_DAY_OF_WEEK*/,			// day number of week
//		5/*FIELD_DAY_OF_MONTH*/,			// day number of month
//		6/*FIELD_DAY_OF_MONTH_XX*/,			// day number of month XX
//		7/*FIELD_DAY_OF_YEAR*/,				// day number of year
//		8/*FIELD_DAY_OF_YEAR_XXX*/,			// day number of year XXX
//		10/*FIELD_MONTH_OF_YEAR*/,		// month number of year
//		11/*FIELD_MONTH_OF_YEAR_XX*/,			// month number of year XX
//		12/*FIELD_YEAR_XX*/,		// year XX
//		13/*FIELD_YEAR_XXXX*/,		// year XXXX
//		14/*FIELD_WEEK_ISO_XX*/,			// week number of year XX
//		15/*FIELD_WEEK_ISO_W*/ | 0x80,		// W
//		16/*FIELD_YEAR_ISO_WEEK_XXXX*/,
//		17/*FIELD_WEEK_CALENDAR_XX*/,			// week number of year XX
//		18/*FIELD_YEAR_CALENDAR_WEEK_XXXX*/,
//	]b;
//	
//	var valueIds = [
//		31/*FIELD_STEPSCOUNT*/,
//		32/*FIELD_STEPSGOAL*/,
//		33/*FIELD_FLOORSCOUNT*/,
//		34/*FIELD_FLOORSGOAL*/,
//		35/*FIELD_NOTIFICATIONSCOUNT*/,
//		36/*FIELD_BATTERYPERCENTAGE*/,
//		30/*FIELD_SEPARATOR_PERCENT*/,
//		37/*FIELD_HEART_MIN*/,
//		38/*FIELD_HEART_MAX*/,
//		39/*FIELD_HEART_AVERAGE*/,
//		40/*FIELD_HEART_LATEST*/,
//		48/*FIELD_CALORIES*/,
//		49/*FIELD_ACTIVE_CALORIES*/,
//		50/*FIELD_INTENSITY*/,
//		51/*FIELD_INTENSITY_GOAL*/,
//		52/*FIELD_SMART_GOAL*/,
//		53/*FIELD_DISTANCE*/,
//		54/*FIELD_DISTANCE_UNITS*/ | 0x80,
//		55/*FIELD_PRESSURE*/,
//		56/*FIELD_PRESSURE_UNITS*/ | 0x80,
//		57/*FIELD_ALTITUDE*/,
//		58/*FIELD_ALTITUDE_UNITS*/ | 0x80,
//		59/*FIELD_TEMPERATURE*/,
//		60/*FIELD_TEMPERATURE_UNITS*/ | 0x80,
//	]b;
	
	var idArray;
	var idArrayValue;
	
//	enum
//	{
//		s_top,
//		
//		s_timeLarge,
//		s_time,
//		s_advanced
//		s_separator,
//		s_date,
//		s_value,
//		s_icon,
//		s_moveBar,
//		s_chart,
//
//		s_largeEdit,
//		s_timeEdit,
//		s_advancedEdit,
//		s_separatorEdit,
//		s_dateEdit,
//		s_valueEdit,
//		s_iconEdit,
//	}

	var fState;

    function initialize()
    {
    	myMenuItem.initialize();

    	fState = 0;
		idArray = 0;
		idArrayValue = 0;
    }
    
    function getString()
    {
    	if (fState<=9/*s_chart*/)
    	{
 			return editorView.safeStringFromJsonData(Rez.JsonData.id_addElementStrings, -1, fState);
		}
    	else if (fState==10/*s_largeEdit*/)
    	{
 			return editorView.getLargeTypeName(idArrayValue);
		}
		else if (fState<=15/*s_valueEdit*/)
		{
			return editorView.getStringTypeName(idArrayValue);
    	}
		else if (fState==16/*s_iconEdit*/)
		{
			return "editing...";
    	}

    	return null;
    }
    
    // up=0 down=1 left=2 right=3
    function hasDirection(d)
    {
    	return (d!=1 || fState!=0/*s_top*/);
    }

    function onEditing(val)
    {
    	if (fState==0/*s_top*/)
    	{
    		if (val<0 && editorView.menuElementGfx>editorView.menuFieldGfx)
    		{
    			return new myMenuItemElementSelect();
    		}
    	}
    	else if (fState<=9/*s_chart*/)
    	{
    		fState = (fState+val+9-1)%9 + 1;
    	}
    	else if (fState==10/*s_largeEdit*/)
    	{
    		idArrayValue = (idArrayValue+val+3)%3;
    	}
		else if (fState<=15/*s_valueEdit*/)
		{
    		idArrayValue = editorView.stringTypeEditing(val, idArray, idArrayValue);
    	}
		else if (fState==16/*s_iconEdit*/)
		{
			editorView.iconTypeEditing(val);
    	}
    
    	return null;
    }
    
    function onNext()
    {
		return onEditing(1);
    }
    
    function onPrevious()
    {
		return onEditing(-1);
    }
    
    function onSelect()
    {
    	var index = -1;
    	
    	var afterIndex = editorView.afterGfxField(editorView.menuFieldGfx);
    	
		if (fState==0/*s_top*/)
		{
			fState = 1/*s_timeLarge*/;
		}
		else if (fState==1/*s_timeLarge*/)
		{
			idArrayValue = 0;
			fState = 10/*s_largeEdit*/;
		}
		else if (fState<=6/*s_value*/)
		{
			idArray = fState-2;
    		idArrayValue = editorView.stringTypeEditing(0, idArray, 0);		// first value in sub array
			fState += 9;
		}
		else if (fState==7/*s_icon*/)
		{
			// don't set index for icons as we handle their creation differently
			var temp = editorView.gfxAddIcon(afterIndex, 0);
			if (temp>=0)
			{
				editorView.menuElementGfx = temp;
				fState += 9;
			}
		}
		else if (fState==8/*s_moveBar*/)
		{
			index = editorView.gfxAddMoveBar(afterIndex);
		}
		else if (fState==9/*s_chart*/)
		{
			index = editorView.gfxAddChart(afterIndex);
		}
		else if (fState==10/*s_largeEdit*/)
		{
			index = editorView.gfxAddLarge(afterIndex, idArrayValue);
		}
		else if (fState<=15/*s_valueEdit*/)
		{
			index = editorView.gfxAddString(afterIndex, idArrayValue);
    	}
		else if (fState<=16/*s_iconEdit*/)
		{
    		return new myMenuItemElementSelect();
    	}

    	if (index>=0)
    	{
    		editorView.menuElementGfx = index;
    		return new myMenuItemElementSelect();
    	}
    	
    	return null;
    }
    
    function onBack()
    {
		if (fState==0/*s_top*/)
		{
			return new myMenuItemFieldEdit();
		}
		else if (fState<=9/*s_chart*/)
		{
			fState = 0;
		}
		else if (fState<=15/*s_valueEdit*/)
		{
			fState -= 9;			
		}
		else if (fState==16/*s_iconEdit*/)
		{
			return new myMenuItemElementSelect();			
		}

    	return null;
    }
}

(:m2app)
class myMenuItemRectangle extends myMenuItem
{
//	enum
//	{
//		r_type,			0
//		r_direction,	1
//		r_color,		2
//		r_unfilled,		3
//		r_position,		4
//		r_w,			5
//		r_h,			6
//		r_vis,			7
//		r_earlier,		8
//		r_later,		9
//		r_delete,		10
//
//		r_x,			11
//		r_y,			12
//		r_xCentre,		13
//		r_yCentre,		14
//		r_tap,			15
//
//		r_typeEdit,		100
//		r_directionEdit,101
//		r_colorEdit,	102
//		r_unfilledEdit,	103
//		r_wEdit,		105
//		r_hEdit,		106
//		r_visEdit,		107
//
//		r_xEdit,		111
//		r_yEdit,		112
//	}

	var fState;

    function initialize()
    {
    	myMenuItem.initialize();

    	fState = 0;
    }
    
    function getString()
    {
    	if (fState==100/*r_typeEdit*/)
    	{
 			return editorView.safeStringFromJsonData(Rez.JsonData.id_rectangleStrings, 1, editorView.rectangleGetType());
    	}
    	else if (fState==101/*r_directionEdit*/)
    	{
 			return editorView.safeStringFromJsonData(Rez.JsonData.id_rectangleStrings, 2, editorView.rectangleGetDirection());
    	}
    	else if (fState==105/*r_wEdit*/)
    	{
    		return "w=" + editorView.rectangleGetWidth();
    	}
    	else if (fState==106/*r_hEdit*/)
    	{
    		return "h=" + editorView.rectangleGetHeight();
    	}
    	else if (fState==107/*r_visEdit*/)
    	{
    		return editorView.fieldVisibilityString();
    	}
    	else if (fState==111/*r_xEdit*/)
    	{
    		return "x=" + editorView.rectanglePositionGetX();
    	}
    	else if (fState==112/*r_yEdit*/)
    	{
    		return "y=" + editorView.rectanglePositionGetY();
    	}
		else if (fState<=15/*r_tap*/)
		{
 			return editorView.safeStringFromJsonData(Rez.JsonData.id_rectangleStrings, 0, fState);
 		}
 		else
 		{
 			return "editing...";	// for x, y, w, h
 		}
    }
    
    // up=0 down=1 left=2 right=3
    function hasDirection(d)
    {
    	return (d!=3 || fState<15/*r_tap*/);
    }

    function onEditing(val)
    {
    	if (fState<=10/*r_delete*/)
    	{
    		fState = (fState+val+11)%11;
    	}
    	else if (fState>=11/*r_x*/ && fState<=15/*r_tap*/)
    	{
    		//fState = (fState+val+5-11)%5 + 11;
    		fState = (fState+val+4-11)%4 + 11;		// removed tap for now
    	}
    	else if (fState==100/*r_typeEdit*/)
    	{
 			editorView.rectangleTypeEditing(val);
    	}
    	else if (fState==101/*r_directionEdit*/)
    	{
 			editorView.rectangleDirectionEditing(val);
    	}
    	else if (fState==102/*r_colorEdit*/ || fState==103/*r_unfilledEdit*/)
    	{
    		editorView.rectangleColorEditing(fState-102/*r_colorEdit*/, val);
    	}
    	else if (fState==105/*r_wEdit*/)
    	{
    		editorView.rectangleWidthEditing(val);
    	}
    	else if (fState==106/*r_hEdit*/)
    	{
    		editorView.rectangleHeightEditing(val);
    	}
    	else if (fState==107/*r_visEdit*/)
    	{
    		editorView.fieldVisibilityEditing(val);
    	}
    	else if (fState==111/*r_xEdit*/)
    	{
    		editorView.rectanglePositionXEditing(val);
    	}
    	else if (fState==112/*r_yEdit*/)
    	{
    		editorView.rectanglePositionYEditing(val);
    	}

    	return null;
    }
    
    function onNext()
    {
    	return onEditing(1);
    }
    
    function onPrevious()
    {
    	return onEditing(-1);
    }
    
    function onSelect()
    {
    	if (fState==4/*r_position*/)
    	{
    		fState = 11/*r_x*/;
    	}
    	else if (fState==8/*r_earlier*/)
    	{
    		editorView.fieldEarlier();
    	}
    	else if (fState==9/*r_later*/)
    	{
    		editorView.fieldLater();
    	}
    	else if (fState==10/*r_delete*/)
    	{
    		editorView.fieldDelete();
    		return new myMenuItemFieldSelect();
    	}
    	else if (fState==13/*r_xCentre*/)
    	{
    		editorView.rectanglePositionCentreX();
    	}
    	else if (fState==14/*r_yCentre*/)
    	{
    		editorView.rectanglePositionCentreY();
    	}
    	else if (fState==15/*r_tap*/)
    	{
    	}
    	else if (fState<100)
    	{
   			fState += 100;

    		if (fState==102/*r_colorEdit*/ || fState==103/*r_unfilledEdit*/)
	    	{
	    		editorView.startColorEditing(editorView.menuFieldGfx+fState-102/*r_colorEdit*/+2/*rect_filled*/);
	    	}
    	}

    	return null;
    }
    
    function onBack()
    {
    	if (fState<=10/*r_delete*/)
    	{
    		return new myMenuItemFieldSelect();
    	}
    	else if (fState>=100)
    	{
    		editorView.endColorEditing();

    		fState -= 100;
    	}
    	else if (fState>=11/*r_x*/)
    	{
    		fState = 4/*r_position*/;
    	}

    	return null;
    }
}

(:m2app)
class myMenuItemRing extends myMenuItem
{
//	enum
//	{
//		r_type,
//		r_font,
//		r_start,
//		r_end,
//		r_direction,
//		r_limit,
//		r_colorFilled,
//		r_colorValue,
//		r_colorUnfilled,
//		r_vis,
//		r_earlier,
//		r_later,
//		r_delete,
//
//		r_typeEdit,
//		r_fontEdit,
//		r_startEdit,
//		r_endEdit,
//		r_directionEdit,
//		r_limitEdit,
//		r_colorFilledEdit,
//		r_colorValueEdit,
//		r_colorUnfilledEdit,
//		r_visEdit,
//	}

	var fState;

    function initialize()
    {
    	myMenuItem.initialize();

		fState = 0;
    }
    
    function getString()
    {
    	if (fState==13/*r_typeEdit*/)
    	{
 			return editorView.safeStringFromJsonData(Rez.JsonData.id_ringStrings2, 1, editorView.ringGetType());    		
    	}
    	else if (fState==14/*r_fontEdit*/)
    	{
 			return editorView.safeStringFromJsonData(Rez.JsonData.id_ringStrings3, -1, editorView.ringGetFont());    		
    	}
    	else if (fState==17/*r_directionEdit*/)
    	{
 			return editorView.safeStringFromJsonData(Rez.JsonData.id_ringStrings, 1, editorView.ringGetDirectionAnti() ? 1 : 0);
    	}
    	else if (fState==18/*r_limitEdit*/)
    	{
 			return editorView.safeStringFromJsonData(Rez.JsonData.id_ringStrings2, 0, editorView.ringGetLimit100() ? 1 : 0);
    	}
    	else if (fState==22/*r_visEdit*/)
    	{
    		return editorView.fieldVisibilityString();
    	}
		else if (fState<=12/*r_delete*/)
		{
 			return editorView.safeStringFromJsonData(Rez.JsonData.id_ringStrings, 0, fState);
		}
		else
		{
			return "editing...";	// for font, start, end
		}
    }
    
    // up=0 down=1 left=2 right=3
    function hasDirection(d)
    {
    	return (d!=3 || fState<13/*r_typeEdit*/);
    }

    function onEditing(val)
    {
       	if (fState<=12/*r_delete*/)
    	{
    		fState = (fState+val+13)%13;
    	}
       	else if (fState==13/*r_typeEdit*/)
    	{
    		editorView.ringTypeEditing(val);
    	}
       	else if (fState==14/*r_fontEdit*/)
    	{
    		editorView.ringFontEditing(val);
    	}
       	else if (fState==15/*r_startEdit*/)
    	{
    		editorView.ringStartEditing(val);
    	}
       	else if (fState==16/*r_endEdit*/)
    	{
    		editorView.ringEndEditing(val);
    	}
       	else if (fState==17/*r_directionEdit*/)
    	{
    		editorView.ringDirectionEditing();
    	}
       	else if (fState==18/*r_limitEdit*/)
    	{
    		editorView.ringLimitEditing();
    	}
       	else if (fState==19/*r_colorFilledEdit*/)
    	{
    		editorView.ringColorEditing(0, val);
    	}
       	else if (fState==20/*r_colorValueEdit*/)
    	{
    		editorView.ringColorEditing(1, val);
    	}
       	else if (fState==21/*r_colorUnfilledEdit*/)
    	{
    		editorView.ringColorEditing(2, val);
    	}
       	else if (fState==22/*r_visEdit*/)
    	{
    		editorView.fieldVisibilityEditing(val);
    	}
    
    	return null;
    }
    
    function onNext()
    {
		return onEditing(1);
    }
    
    function onPrevious()
    {
		return onEditing(-1);
    }
    
    function onSelect()
    {
    	if (fState<=9/*r_vis*/)
    	{
    		fState += 13;

	       	if (fState>=19/*r_colorFilledEdit*/ && fState<=21/*r_colorUnfilledEdit*/)
	    	{
	    		editorView.startColorEditing(editorView.menuFieldGfx+fState-19/*r_colorFilledEdit*/+5);
	    	}
    	}
    	else if (fState==10/*r_earlier*/)
    	{
    		editorView.fieldEarlier();
    	}
    	else if (fState==11/*r_later*/)
    	{
    		editorView.fieldLater();
    	}
    	else if (fState==12/*r_delete*/)
    	{
    		editorView.fieldDelete();
    		return new myMenuItemFieldSelect();
    	}

    	return null;
    }
    
    function onBack()
    {
    	if (fState<=12/*r_delete*/)
    	{
    		return new myMenuItemFieldSelect();
    	}
    	else
    	{
	       	//if (fState==16/*r_colorFilledEdit*/ || fState==17/*r_colorUnfilledEdit*/)
	    	//{
	    		editorView.endColorEditing();
	    	//}

    		fState -= 13;
    	}

   		return null;
    }
}

(:m2app)
class myMenuItemSeconds extends myMenuItem
{
//	enum
//	{
//		s_font,
//		s_refresh,
//		s_color,
//		s_color5,
//		s_color10,
//		s_color15,
//		s_color0,
//		s_vis,
//		s_delete,
//
//		s_fontEdit,
//		s_refreshEdit,
//		s_colorEdit,
//		s_color5Edit,
//		s_color10Edit,
//		s_color15Edit,
//		s_color0Edit,
//		s_visEdit,
//	}

	var fState;

    function initialize()
    {
    	myMenuItem.initialize();

    	fState = 0;
    }
    
    function getString()
    {
    	if (fState==9/*s_fontEdit*/)
    	{
			return editorView.safeStringFromJsonData(Rez.JsonData.id_secondsStrings2, -1, editorView.secondsGetFont());
    	}
    	else if (fState==10/*s_refreshEdit*/)
    	{
			return editorView.safeStringFromJsonData(Rez.JsonData.id_secondsStrings, 1, editorView.secondsGetRefresh());
    	}
    	else if (fState==16/*s_visEdit*/)
    	{
    		return editorView.fieldVisibilityString();
    	}
 		else if (fState<=8/*s_delete*/)
 		{
 			return editorView.safeStringFromJsonData(Rez.JsonData.id_secondsStrings, 0, fState);
 		}
 		else
 		{
 			return "editing...";	// for font
 		}
    }
    
    // up=0 down=1 left=2 right=3
    function hasDirection(d)
    {
    	return (d!=3 || fState<9/*s_fontEdit*/);
    }

    function onEditing(val)
    {
    	if (fState<=8/*s_delete*/)
    	{
    		fState = (fState+val+9)%9;
    	}
    	else if (fState==9/*s_fontEdit*/)
    	{
    		editorView.secondsFontEditing(val);
    	}
    	else if (fState==10/*s_refreshEdit*/)
    	{
    		editorView.secondsRefreshEditing(val);
    	}
    	else if (fState==16/*s_visEdit*/)
    	{
    		editorView.fieldVisibilityEditing(val);
    	}
    	else
    	{
    		editorView.secondsColorEditing(fState-11/*s_colorEdit*/, val);
    	}
    	
    	return null;
    }
    
    function onNext()
    {
   		return onEditing(1);
    }
    
    function onPrevious()
    {
   		return onEditing(-1);
    }
    
    function onSelect()
    {
    	if (fState<=7/*s_vis*/)
    	{
    		fState += 9;

	    	if (fState>=11/*s_colorEdit*/ && fState<=15/*s_color0Edit*/)
	    	{
	    		editorView.startColorEditing(editorView.menuFieldGfx+fState+2-11/*s_colorEdit*/);
	    	}
    	}
    	else if (fState==8/*s_delete*/)
    	{
    		editorView.fieldDelete();
    		return new myMenuItemFieldSelect();
    	}
    	
    	return null;
    }
    
    function onBack()
    {
    	if (fState<=8/*s_delete*/)
    	{
    		return new myMenuItemFieldSelect();
    	}
    	else
    	{
	    	//if (fState>=11/*s_colorEdit*/ && fState<=15/*s_color0Edit*/)
	    	//{
	    		editorView.endColorEditing();
	    	//}

    		fState -= 9;
    	}

   		return null;
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
