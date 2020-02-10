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
	
	var isTurkish = false;

	//const PROFILE_NUM_USER = 24;		// number of user profiles
	
	//const PROFILE_NUM_PRESET = 17;		// number of preset profiles (in the jsondata resource)
	const PROFILE_NUM_PRESET = 1;		// number of preset profiles (in the jsondata resource)

	var displaySize = 240;
	var displayHalf = 120;

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
	var propKerningOn = false;
	var propDawnDuskMode = 1;		// 1==civil, 2==nautical, 3==astronomical 
    var propBatteryHighPercentage = 75;
	var propBatteryLowPercentage = 25;
	var prop2ndTimeZoneOffset = 0;		// in minutes
    var propMoveBarAlertTriggerLevel = 1;

    var propFieldFontSystemCase = 0;	// 0, 1, 2
    var propFieldFontUnsupported = 1;	// 0=xtiny to 4=large

	// for seconds indicator & text:
    var propSecondIndicatorOn = false;
    var propSecondGfxIndex = -1;
	var propSecondBufferIndex = 30/*MAX_DYNAMIC_RESOURCES*/;
	
	//const BUFFER_SIZE = 62;
	var bufferX = 0;
	var bufferY = 0;
	
	// just for seconds text:
    var propSecondTextMode = 0;		// 0=off, 1=cheap, 2=true
	var bufferW = 0;
	var bufferH = 0;

	// just for seconds indicator:
	var bufferPositionCounter = -1;	// ensures buffer will get updated first time
	var propSecondResourceIndex = 30/*MAX_DYNAMIC_RESOURCES*/;
    var propSecondRefreshStyle = 0;
    var propSecondAligned = true;
	var propSecondColorIndexArray = new[60]b;
	var propSecondPositionsIndex = 30/*MAX_DYNAMIC_RESOURCES*/;

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

    (:m2face)
	var honestyCheckbox = false;

	var demoProfilesOn = false;
	var demoProfilesFirst = 24/*PROFILE_NUM_USER*/;
	var demoProfilesLast = PROFILE_NUM_PRESET+24/*PROFILE_NUM_USER*/-1;
	var demoProfilesCurrentProfile = -1;
	var demoProfilesCurrentEnd = 0;

	var propSunAltitudeAdjust = false;
	
    (:m2face)
	var propStatusUpdateRate = 15;

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
	
//	//	FIELD_SHAPE_CIRCLE = 0,
//	//	//!FIELD_SHAPE_CIRCLE_SOLID = 1,
//	//	//!FIELD_SHAPE_ROUNDED = 2,
//	//	//!FIELD_SHAPE_ROUNDED_SOLID = 3,
//	//	//!FIELD_SHAPE_SQUARE = 4,
//	//	//!FIELD_SHAPE_SQUARE_SOLID = 5,
//	//	//!FIELD_SHAPE_TRIANGLE = 6,
//	//	//!FIELD_SHAPE_TRIANGLE_SOLID = 7,
//	//	//!FIELD_SHAPE_DIAMOND = 8,
//	//	//!FIELD_SHAPE_DIAMOND_SOLID = 9,
//	//	//!FIELD_SHAPE_STAR = 10,
//	//	//!FIELD_SHAPE_STAR_SOLID = 11,
//	//	//!FIELD_SHAPE_ALARM = 12,
//	//	//!FIELD_SHAPE_LOCK = 13,
//	//	//!FIELD_SHAPE_PHONE = 14,
//	//	//!FIELD_SHAPE_NOTIFICATION = 15,
//	//	//!FIELD_SHAPE_FIGURE = 16,
//	//	//!FIELD_SHAPE_BATTERY = 17,
//	//	//!FIELD_SHAPE_BATTERY_SOLID = 18,
//	//	//!FIELD_SHAPE_BED = 19,
//	//	//!FIELD_SHAPE_FLOWER = 20,
//	//	//!FIELD_SHAPE_FOOTSTEPS = 21,
//	//	//!FIELD_SHAPE_NETWORK = 22,
//	//	//!FIELD_SHAPE_STAIRS = 23,
//	//	//!FIELD_SHAPE_PHONE_HANDSET = 24,
//	//	//!FIELD_SHAPE_STOPWATCH = 25,
//	//	//!FIELD_SHAPE_FIRE = 26,
//	//	//!FIELD_SHAPE_HEART = 27,
//	//	//!FIELD_SHAPE_SUNRISE = 28,
//	//	//!FIELD_SHAPE_SUNSET = 29,
//	//	//!FIELD_SHAPE_SUN = 30,
//	//	//!FIELD_SHAPE_MOON = 31,
//	//	//!FIELD_SHAPE_MOUNTAIN = 32,
//	//	//!FIELD_SHAPE_BATTERY_FILL = 33,

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
	//	STATUS_DAWNDUSK_LIGHT = 25,
	//	STATUS_DAWNDUSK_DARK = 26,
	//	STATUS_HR_ZONE_0 = 27,
	//	STATUS_HR_ZONE_1 = 28,
	//	STATUS_HR_ZONE_2 = 29,
	//	STATUS_HR_ZONE_3 = 30,
	//	STATUS_HR_ZONE_4 = 31,
	//	STATUS_HR_ZONE_5 = 32,
	//	STATUS_HR_ZONE_6 = 33,
	//
	//	STATUS_NUM = 34
	//}
		
	var colorArray = new[64]b;

	//const COLOR_NOTSET = -2;		// just used in the code to indicate no color set
	//const COLOR_FOREGROUND = -1;	// use default foreground color

	//const COLOR_SAVE = 2;		// offset used when storing colors to gfx array
	//const COLOR_ONE = 1;		// used when editing colors to allow default foreground but not notset  
	
	function getColor64FromGfx(i)
	{
		i -= 2/*COLOR_SAVE*/;
	
		if (i<0 || i>=64)
		{
			return ((i==-1/*COLOR_FOREGROUND*/) ? propForegroundColor : -2/*COLOR_NOTSET*/); 
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

	function gfxMinMaxInPlace(index, min, max)
	{
		gfxData[index] = getMinMax(gfxData[index], min, max); 
		return gfxData[index];
	}

//	function getMin(a, b)
//	{
//		return (a<b) ? a : b;
//	}

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
//			46,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,
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

	function getSafeBoolean(v)
	{
		return (((v == null) || !(v instanceof Boolean)) ? false : v);
	}

	function getSafeNumber(v)
	{
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

	function getSafeFloat(v)
	{
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
	
	function getSafeString(v)
	{
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
	
	function getBooleanFromArray(pArray, p)
	{
		return ((p>=0 && p<pArray.size()) ? getSafeBoolean(pArray[p]) : false);
	}
	
	function getNumberFromArray(pArray, p)
	{
		return ((p>=0 && p<pArray.size()) ? getSafeNumber(pArray[p]) : 0);
	}
		
	function getFloatFromArray(pArray, p)
	{
		return ((p>=0 && p<pArray.size()) ? getSafeFloat(pArray[p]) : 0.0);
	}

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
		
		var v = null;
		try
		{
			v = applicationProperties.getValue(p);
		}
		catch (e)
		{
		}
		return getSafeBoolean(v);
	}
	
	function propertiesGetNumber(p)
	{
		var v = null;
		try
		{
			v = applicationProperties.getValue(p);
		}
		catch (e)
		{
		}
		return getSafeNumber(v);
	}

//	function propertiesGetFloat(p)
//	{
//		var v = null;
//		try
//		{
//			v = applicationProperties.getValue(p);
//		}
//		catch (e)
//		{
//		}
//		return getSafeFloat(v);
//	}
	
	function propertiesGetString(p)
	{	
		var v = null;
		try
		{
			v = applicationProperties.getValue(p);
		}
		catch (e)
		{
		}
		return getSafeString(v);
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
		var l = 0;
		if (s.find("SUNRISE")==0)
		{
			t[0] = 0x01/*PROFILE_START_SUNRISE*/;
			l = 7;
		}
		else if (s.find("SUNSET")==0)
		{
			t[0] = 0x02/*PROFILE_START_SUNSET*/;
			l = 6;
		}
		else if (s.find("DAWN")==0)
		{
			t[0] = 0x0100/*PROFILE_START_DAWN*/;
			l = 4;
		}
		else if (s.find("DUSK")==0)
		{
			t[0] = 0x0200/*PROFILE_START_DUSK*/;
			l = 4;
		}
		else
		{
			t[0] = 0;
			adjust = 0;
		}

		s = s.substring(l, s.length());

		var charArray = s.toCharArray();
		var charArraySize = charArray.size();
		parseIndex = 0;
		
		var sign = parseSign(charArray, charArraySize);
		var n = parseTwoNumbers(charArray, charArraySize);

		t[1] = getMinMax(adjust + sign*(n[0]*60 + n[1]), 0, 24*60);		// convert hours to minutes and check in correct range

		return t;		
	}

	function addStringToCharArray(s, toArray, toLen, toMax, withDiacritics)
	{
		var charArray = s.toCharArray();
		var charArraySize = charArray.size();
		
		if (toLen+charArraySize+(withDiacritics?charArraySize:0) <= toMax)
		{ 
			for (var i=0; i<charArraySize; i++)
			{
				if (withDiacritics)
				{
					var c = getMyCharDiacritic(charArray[i]);
					toArray[toLen] = c[0];
					toArray[toLen + charArraySize] = ((c[1]>700) ? c[1].toChar() : 0);
				}
				else
				{				
					toArray[toLen] = charArray[i];
				}
			
				toLen += 1;
			}
		}
	
		return toLen;
	}
	
//	function addStringToCharArrayWithDiacritics(s, toArray, toLen, toMax)
//	{
//		var charArray = s.toCharArray();
//		var charArraySize = charArray.size();
//		
//		if (toLen+(charArraySize*2) <= toMax)
//		{ 
//			for (var i=0; i<charArraySize; i++)
//			{
//				var c = getMyCharDiacritic(charArray[i]);
//
//				toArray[toLen] = c[0];
//				toArray[toLen + charArraySize] = ((c[1]>700) ? c[1].toChar() : 0);
//
//				toLen += 1;
//			}
//		}
//	
//		return toLen;
//	}
	
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

		var tempStr = WatchUi.loadResource(Rez.Strings.Turkish);
		isTurkish = (tempStr!=null && tempStr.length()>0);
		tempStr = null;

		//tempStr = WatchUi.loadResource(Rez.Strings.AppName);
		//System.println("appname=" + tempStr);

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

		var timeNow = Time.now();

		initHeartSamples(timeNow);

		// remember which profile was active and also any profileDelayEnd value
		// and all the profile times
		loadMemoryData(timeNow.value());
		
//System.println("Timer loadmem=" + (System.getTimer()-timeStamp) + "ms");

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
//    function onShow()
//    {
//        //System.println("onShow");
//    }

    // Called when this View is removed from the screen (including the app ending).
    // Save the state of this View here. This includes freeing resources from memory.
//    function onHide()
//    {
//        //System.println("onHide");
//	}

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
        if (glanceActive)
        {
	        glanceActive = false;			// on only
	        WatchUi.requestUpdate();
	    }
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
		demoProfilesLast = ((n[1]>(24/*PROFILE_NUM_USER*/+PROFILE_NUM_PRESET)) ? (24/*PROFILE_NUM_USER*/+PROFILE_NUM_PRESET) : n[1]) - 1;	// convert from user to code index

		propSunAltitudeAdjust = propertiesGetBoolean("SA");
		propStatusUpdateRate = getMinMax(propertiesGetNumber("SU"), 1, 60);
	}
	
    (:m2app)
	function getSettingsForFaceOrApp()
	{
	}
	
	function getPresetProfileString(profileIndex, n)
	{
		var jsonData = Rez.JsonData;
		var loadPreset = [jsonData.id_preset0, jsonData.id_preset1, jsonData.id_preset2, jsonData.id_preset3, jsonData.id_preset4, jsonData.id_preset5, jsonData.id_preset6, jsonData.id_preset7, jsonData.id_preset8, jsonData.id_preset9, jsonData.id_preset10, jsonData.id_preset11, jsonData.id_preset12, jsonData.id_preset13, jsonData.id_preset14, jsonData.id_preset15, jsonData.id_preset16];
		return ((profileIndex>=24/*PROFILE_NUM_USER*/ && profileIndex<(24/*PROFILE_NUM_USER*/+PROFILE_NUM_PRESET)) ? WatchUi.loadResource(loadPreset[profileIndex - 24/*PROFILE_NUM_USER*/])[n] : "");
	}

	function getProfileString(profileIndex)
	{
		return ((profileIndex<24/*PROFILE_NUM_USER*/) ? applicationStorage.getValue("P" + profileIndex) : getPresetProfileString(profileIndex, 1));
	}
	
	function profileTimeString(t, profileFlags)
	{
		var s = "";
	
		if ((profileFlags&(0x01/*PROFILE_START_SUNRISE*/|0x02/*PROFILE_START_SUNSET*/|0x0100/*PROFILE_START_DAWN*/|0x0200/*PROFILE_START_DUSK*/))!=0)
		{
			t -= 12*60;	// remove 12 hours added to make positive for storage

			//var k = (((profileFlags&0x02)/0x02) + 2*((profileFlags&0x0100)/0x0100) + 3*((profileFlags&0x0200)/0x0200))%4; 
			//s = ["Sunrise", "Sunset", "Dawn", "Dusk"][k];

			//s = ((profileFlags&0x01/*PROFILE_START_SUNRISE*/)!=0) ? "Sunrise" :
			//	(((profileFlags&0x02/*PROFILE_START_SUNSET*/)!=0) ? "Sunset" :
			//	(((profileFlags&0x0100/*PROFILE_START_DAWN*/)!=0) ? "Dawn" : "Dusk"));

			if ((profileFlags&0x01/*PROFILE_START_SUNRISE*/)!=0)
			{
				s = "Sunrise";
			}
			else if ((profileFlags&0x02/*PROFILE_START_SUNSET*/)!=0)
			{
				s = "Sunset";
			}
			else if ((profileFlags&0x0100/*PROFILE_START_DAWN*/)!=0)
			{
				s = "Dawn";
			}
			else
			{
				s = "Dusk";
			}
			
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
		var daysNumber = 0;
		var startTime = 0;
		var endTime = 0;
		var profileFlags = 0;
		var glanceProfile = 0;
		var blockRandom = false;
		var randomEvents = 0;

		if (profileIndex>=0 && profileIndex<24/*PROFILE_NUM_USER*/)	// not for private or preset profiles
		{
			var ptdIndex = profileIndex*6;
		
			// set the profile properties from our profile times array			
			var days = profileTimeData[ptdIndex + 2];		
			for (var i=0; i<7; i++)
			{
				if ((days&(0x1<<i))!=0)
				{
					daysNumber *= 10;
					daysNumber += i+1;
				}
			}
	
			startTime = profileTimeData[ptdIndex + 0];
			endTime = profileTimeData[ptdIndex + 1];
			profileFlags = profileTimeData[ptdIndex + 3];
			glanceProfile = ((profileTimeData[ptdIndex + 5] >= 0) ? profileTimeData[ptdIndex + 5] : 0);		// glance profile
			blockRandom = ((profileFlags&0x10/*PROFILE_BLOCK_MASK*/)!=0);
			randomEvents = profileTimeData[ptdIndex + 4];		
		}

		applicationProperties.setValue("PD", daysNumber);
		applicationProperties.setValue("PS", profileTimeString(startTime, profileFlags));
		applicationProperties.setValue("PE", profileTimeString(endTime, profileFlags>>2));
		applicationProperties.setValue("35", glanceProfile);		// glance profile
		applicationProperties.setValue("PB", blockRandom);
		applicationProperties.setValue("PR", randomEvents);		
	}

	(:m2face)		
	function getProfileTimeDataFromPropertiesFaceOrApp(profileIndex)
	{
		if (profileIndex>=0 && profileIndex<24/*PROFILE_NUM_USER*/)	// not for private or preset profiles
		{
			var ptdIndex = profileIndex*6;

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
			profileTimeData[ptdIndex + 2] = days;

			var startTime = propertiesGetTime("PS");
			var endTime = propertiesGetTime("PE");
			profileTimeData[ptdIndex + 0] = startTime[1];		// start time 0-1440
			profileTimeData[ptdIndex + 1] = endTime[1];		// end time 0-1440
			
			profileTimeData[ptdIndex + 5] = getMinMax(propertiesGetNumber("35"), 0, 99);	// glance profile

			var profileFlags = startTime[0] | (endTime[0] << 2);
			if (propertiesGetBoolean("PB"))
			{
				profileFlags |= 0x10/*PROFILE_BLOCK_MASK*/;
			}
			profileTimeData[ptdIndex + 3] = profileFlags;

			profileTimeData[ptdIndex + 4] = getMinMax(propertiesGetNumber("PR"), 0, 0xFF/*PROFILE_EVENTS_MASK*/);
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
		if (profileNumber>=0 && profileNumber<(24/*PROFILE_NUM_USER*/+PROFILE_NUM_PRESET))
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
		if (profileNumber>=0 && profileNumber<24/*PROFILE_NUM_USER*/)
		{
			var s = propertiesGetString("EP") + propertiesGetString("EP2");
			applicationStorage.setValue("P" + profileNumber, s);
			s = null;

			getProfileTimeDataFromPropertiesFaceOrApp(profileNumber);
			saveMemoryData();		// remember new values
		}
	}
	
	function copyPropertyStringToGfx()
	{
		// load the Gfx from our property strings
		var s = propertiesGetString("EP") + propertiesGetString("EP2");

//		// hyper
//		s = "01YW2552Vy11WDPO1011WlVv03VV2VV4L0G3N213Ve2Vm4R0Vw1WjWI020Vj522Vj121Vj19dXO00Vf01WjYB03Va2Vp4I0Vq1WlVe03Vr213Xw213N213Vt213Xy211WlO0ZT001111101WlXZ036213N213XD213N213D213N213X7211WlXt03Vf21";

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
			saveMemoryData();		// remember new values
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
		
    function formatHourForDisplayString(h, use24Hour, addLeadingZero)
    {
        // 12 or 24 hour, and check for adding a leading zero
        return (use24Hour ? h : (((h+11)%12) + 1)).format(addLeadingZero ? "%02d" : "%d"); 
    }
    
//	function printMem(s)
//	{
//		var stats = System.getSystemStats();
//		System.println("free=" + stats.freeMemory + " " + s);
//	}
  
//	var hyperNum = -2;
//	var hyperHadPartial = false;
//
//  	var hyperSec = 0;
//  	var hyperLeave = false;
    
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

//hyperNum++;
//
//hyperLeave = false;
//if (hyperHadPartial && !glanceActive) 
//{
//	if (second!=0 && ((second-hyperSec+60)%60)<=1)
//	{
//		hyperLeave = true;
//	}
//}
//hyperSec = second;
//
//if (hyperLeave)
//{
//	return;
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
			
			handleSettingsChanged(second);		// save/load etc

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
			loadDynamicResources(dc);

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

//if (hyperNum<0)
//{
//	return;
//}

		if (propSecondIndicatorOn && doDrawGfx)
		{
			if (propSecondTextMode!=0)
			{
				var bufferBitmap = getDynamicResource(propSecondBufferIndex);
		        if (bufferBitmap!=null)
		        {
					drawBackgroundToDc(null);	// and draw the background into the buffer
				}
			}
			else
			{
				// draw the seconds indicator to the screen
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
	function drawBufferForSeconds(secondsIndex, dc)
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
        			if (propSecondColorIndexArray[i]!=(-2/*COLOR_NOTSET*/+2/*COLOR_SAVE*/))	// if second is visible
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
//    	hyperHadPartial = true;
//    	if (hyperNum<0)
//    	{
//        	WatchUi.requestUpdate();
//    		return;
//    	}
//    	else if (hyperLeave)
//    	{
//    		return;
//    	}

    	var clockTime = System.getClockTime();
    	updateTimeNowValue = Time.now().value();
    	var minute = clockTime.min;
    	var second = clockTime.sec;

    	sampleHeartRate(second, second!=lastPartialUpdateSec);
    
    	// check for some status icons changing dynamically
    	// - see if the state has changed since the last call to onUpdate
    	if ((second%propStatusUpdateRate)==0)
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
	    	if (propSecondTextMode!=0)
	    	{
				var s;
				var offset;
				
				if ((lastPartialUpdateSec/10) != (second/10))	// if 1st digit changes
				{
					s = second.format("%02d");	// draw both digits:
					offset = 0;
				}
				else
				{
					// drawing just 1 digit is 5% cheaper only 7100 -> 6700 (and 26600->22100)
					s = "" + (second%10);	// draw just 2nd digit:
					offset = bufferW/2;
				}
	    		
   				dc.setClip(bufferX + offset, bufferY, bufferW - offset, bufferH);

				// draw the background (buffer only exists for FIELD_SECOND_TRUE)		
				var bufferBitmap = getDynamicResource(propSecondBufferIndex);
		        if (bufferBitmap!=null)
		        {
					dc.drawBitmap(bufferX, bufferY, bufferBitmap);
				}
				
				// draw the text
				var dynamicResource = getDynamicResourceFromGfx(propSecondGfxIndex+2/*string_font*/);	// also 2/*large_font*/ is the same luckily
				if (dynamicResource!=null)
				{
					// also 3/*large_color*/ is the same luckily
			        dc.setColor(getColor64FromGfx(gfxData[propSecondGfxIndex+3/*string_color*/]), (bufferBitmap==null) ? propBackgroundColor : -1/*COLOR_TRANSPARENT*/);	
	        		dc.drawText(bufferX + offset, bufferY - 1, dynamicResource, s, 2/*TEXT_JUSTIFY_LEFT*/);		// need to draw 1 pixel higher than expected ...
				}
			}
			else
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
		 	}
        }

 		lastPartialUpdateSec = second;	// set after calling doPartialUpdateSec
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

			// clear the previous second (if it was drawn in the first place)
	        if (clearIndex>=0 && propSecondColorIndexArray[clearIndex]!=(-2/*COLOR_NOTSET*/+2/*COLOR_SAVE*/))
	        {
				var bufferBitmap = getDynamicResource(propSecondBufferIndex);
		        if (bufferBitmap!=null)
		        {
					drawBufferForSeconds(clearIndex, dc);
	
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
			
						// In this mode we also always draw the indicator at 0s (propSecondAligned)
						// Or for !propSecondAligned then also need to check the previous one when start clearing
						// - so check if that needs redrawing too after erasing the indicator at 1s
						if (secondsIndex==1)
						{
							var prevIndex = (clearIndex+59)%60; 
							drawSecond(dc, prevIndex, prevIndex);
						}
						
//						if (propSecondAligned)
//						{
//							if (clearIndex==1)
//							{
//								drawSecond(dc, 0, 0);
//							}
//						}
//						else
//						{
//							if (clearIndex==0)
//							{
//								drawSecond(dc, 59, 59);
//							}
//						}
					}
		       	}
			}
			
			// now draw the correct second
			if (!refreshAlternateClearing)
			{
        		var s = (propSecondAligned ? secondsIndex : (secondsIndex+59)%60);
        		if (propSecondColorIndexArray[s]!=(-2/*COLOR_NOTSET*/+2/*COLOR_SAVE*/))
        		{
	    			setSecondClip(dc, s);
	   				drawSecond(dc, s, s);
	   			}
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

	    	var curCol64 = -2/*COLOR_NOTSET*/+2/*COLOR_SAVE*/;
	    	for (var index=startIndex; index<=endIndex; index++)
	    	{
	    		// show second clip region
	    		//if (bufferPositionCounter>=0)
	    		//{
			    // 	dc.setColor(-1/*COLOR_TRANSPARENT*/, Graphics.COLOR_RED);
			    // 	dc.clear();
			    //}

				if (propSecondColorIndexArray[index] != (-2/*COLOR_NOTSET*/+2/*COLOR_SAVE*/))	// if not set then don't draw anything!
				{
			        if (curCol64 != propSecondColorIndexArray[index])
			        {
						curCol64 = propSecondColorIndexArray[index];
			       		dc.setColor(getColor64FromGfx(curCol64), -1/*COLOR_TRANSPARENT*/);	// seconds color
			       	}
			       	//dc.setColor(getColor64FromGfx(curCol64), Graphics.COLOR_RED);	// show background of whole font character
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
    }

	function getProfileSunTime(time, t1)
	{
		if ((t1&(0x01/*PROFILE_START_SUNRISE*/|0x02/*PROFILE_START_SUNSET*/|0x0100/*PROFILE_START_DAWN*/|0x0200/*PROFILE_START_DUSK*/))!=0)
		{
			// remove the 12 hour offset used when it is saved to storage
			// note we add this on rather than subtracting since we are doing modulo 24*60 later (and want the value to be positive)
			time += 12*60;
		
			// riseSetIndex==0 is sunrise
			// riseSetIndex==1 is sunset
			var t;
			if (t1>=0x0100/*PROFILE_START_DAWN*/)
			{
				t = sunTimes[8 + ((t1&0x0200/*PROFILE_START_DUSK*/)/0x0200/*PROFILE_START_DUSK*/)];
			}
			else
			{
				t = sunTimes[(t1&0x02/*PROFILE_START_SUNSET*/)/0x02/*PROFILE_START_SUNSET*/];
			}
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
				if (profileActive>=0 && profileActive<24/*PROFILE_NUM_USER*/)
				{
					var profileActiveGlanceProfile = profileTimeData[profileActive*6 + 5];
					if (profileActiveGlanceProfile>0 && profileActiveGlanceProfile<=(24/*PROFILE_NUM_USER*/+PROFILE_NUM_PRESET))
					{
						doActivate = profileActiveGlanceProfile-1;
						profileGlanceReturn = profileActive;	// return to this profile after glance 
					}
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
			var randomProfiles = new[24/*PROFILE_NUM_USER*/];
			var randomEvents = new[24/*PROFILE_NUM_USER*/];
			var randomEventsTotal = 0;
			
			for (var i=0; i<24/*PROFILE_NUM_USER*/; i++)
			{
				var ptdIIndex = i*6;
				if (autoActivate<0)	// not found a profile to activate yet
				{
					var startTime = profileTimeData[ptdIIndex + 0];
					var endTime = profileTimeData[ptdIIndex + 1];

					// see if the start or end time uses sunrise/sunset
					var sunFlags = profileTimeData[ptdIIndex + 3];					
					if ((sunFlags&(0x01/*PROFILE_START_SUNRISE*/|0x02/*PROFILE_START_SUNSET*/|0x04/*PROFILE_END_SUNRISE*/|0x08/*PROFILE_END_SUNSET*/|
								0x0100/*PROFILE_START_DAWN*/|0x0200/*PROFILE_START_DUSK*/|0x0400/*PROFILE_END_DAWN*/|0x0800/*PROFILE_END_DUSK*/))!=0)
					{
						calculateSun(dateInfoShort);
						
						startTime = getProfileSunTime(startTime, sunFlags);
						endTime = getProfileSunTime(endTime, sunFlags>>2);
					}
					
					var dayFlags = profileTimeData[ptdIIndex + 2];
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

				var numEvents = profileTimeData[ptdIIndex + 4];
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
			if (doActivate>=0 && doActivate<24/*PROFILE_NUM_USER*/ && (profileTimeData[doActivate*6 + 3]&0x10/*PROFILE_BLOCK_MASK*/)==0)
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
	
	(:m2app)
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
	var dayOfYear;		// the day number of the year (1-365)
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
	
	function calculateDayWeekYearData(index, dateInfoMedium)
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
 		var numberInWeekOfJan1 = ((dateInfoStartOfYear.day_of_week - updateFirstDayOfWeek + 7) % 7);	// 0-6
		var weeks = (days + numberInWeekOfJan1) / 7;
		var year = dateInfoMedium.year;

		var numberInWeekOfThu = ((gregorian.DAY_THURSDAY - updateFirstDayOfWeek + 7) % 7);	// 0-6
		
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
			var numberInWeekOfJan1PrevYear = ((dateInfoStartOfPrevYear.day_of_week - updateFirstDayOfWeek + 7) % 7);	// 0-6
			
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
			var numberInWeekOfJan1NextYear = ((dateInfoStartOfNextYear.day_of_week - updateFirstDayOfWeek + 7) % 7);	// 0-6
			
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

	var heartRateZones;
	var heartMaxZone5 = 200;

	function initHeartSamples(timeNow)
	{
		heartStarting = timeNow.value();	// set start time for initial frequent heart updates

		for (var i=0; i<60; i++)
		{
			heartSamples[i] = 255;	// means not set
			heartDisplayBins[i/5/*heartBinSize*/] = 0;
		}
		
		var userProfile = UserProfile.getProfile();

		heartRateZones = userProfile.getHeartRateZones(0/*UserProfile.HR_ZONE_SPORT_GENERIC*/);
		if (heartRateZones!=null && (heartRateZones instanceof Array) && heartRateZones.size()>5)
		{
			heartMaxZone5 = heartRateZones[5];
			if (heartMaxZone5==null || heartMaxZone5<=0)	// max must be at least 1 to avoid potential zero divide
			{
				heartMaxZone5 = 200;
			}
		}
		else
		{
			heartRateZones = [100, 120, 140, 160, 180, 200];
		}

		// ERA reporting a crash here ... so add some checks
		//dailyRestCalories = 1.2*((10.0/1000.0)*userProfile.weight + 6.25*userProfile.height - 5.0*(dateInfoMedium.year-userProfile.birthYear) + ((userProfile.gender==1/*GENDER_MALE*/)?5:(-161)));
		if (userProfile.weight!=null && userProfile.height!=null && userProfile.birthYear!=null && userProfile.gender!=null)
		{
			var currentYear = Time.Gregorian.info(timeNow, Time.FORMAT_MEDIUM).year;
			dailyRestCalories = (12.2/1000.0)*userProfile.weight + 7.628*userProfile.height - 6.116*(currentYear-userProfile.birthYear) + ((userProfile.gender==1/*GENDER_MALE*/)?5.2:(-197.6));
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

	var dailyRestCalories = 0;

	function getRestCalories(timeNowInMinutesToday)
	{
		return ((dailyRestCalories * timeNowInMinutesToday) / (24*60) + 0.5).toNumber();  
	}

	function getActiveCalories(calories, timeNowInMinutesToday)
	{
		return getMax(getNullCheckZero(calories) - getRestCalories(timeNowInMinutesToday), 0);
	}
	
	var stlTrainingLoad = 1.0;
	
	var stlHistoryUpdate;
	var stlHistoryCount;
	var stlHistorySum;
	
	var stlAverage = 0;		// average number of active calories per day
	var stlAverageUpdate;	// when average was last updated

	function stlCalcHistory()
	{
		if (stlHistoryUpdate!=updateTimeTodayValue)		// new day
		{
			stlHistoryUpdate = updateTimeTodayValue;

			stlHistoryCount = 0;
			stlHistorySum = 0;
	
			var historyArray = ActivityMonitor.getHistory();	// most recent first, up to 7
			if (historyArray!=null)
			{
				var nextDayStart = updateTimeTodayValue;
				
				for (var i=0; i<historyArray.size(); i++)
				{
					if (historyArray[i].startOfDay!=null)
					{
						var startOfDayValue = historyArray[i].startOfDay.value();
						
						var daysAgo = ((updateTimeTodayValue - startOfDayValue) + 720*60)/(1440*60);
						if (daysAgo>0)			// not today
						{
							var timeToNextDay = (nextDayStart - startOfDayValue)/60;				// how long from day to next day
							var activeCalories = getActiveCalories(historyArray[i].calories, timeToNextDay);
							
							// numDays==3 then want scale 5, 4, 3
							// numDays==4 then want scale 5, 5, 4, 3
							//var scale = getMinMax(3 + numDays - daysAgo, 0, 5) * 1440;
							var scale = Math.pow(0.8, daysAgo) * 1440;

							stlHistorySum += activeCalories*scale;
							stlHistoryCount += scale;
						}
						
						nextDayStart = startOfDayValue;
					}
				}
			}
		}

//stlHistoryCount = 0;
//stlHistorySum = 0;
//for (var i=0; i<7; i++)
//{
//	var daysAgo = i+1;
//	if (daysAgo>0)			// not today
//	{
//		var activeCalories = [1200, 200, 800, 600, 400, 100, 100, 100, 100, 100][daysAgo-1];
//						
//		// numDays==3 then want scale 5, 4, 3
//		// numDays==4 then want scale 5, 5, 4, 3
//		//var scale = getMinMax(3 + numDays - daysAgo, 0, 5) * 1440;
//		var scale = Math.pow(0.8, daysAgo) * 1440;
//		
//		stlHistorySum += activeCalories*scale;
//		stlHistoryCount += scale;
//	}
//}
	}
	
	function stlCheckAverage()
	{
		// update rolling average when the day changes
		if (stlAverageUpdate!=updateTimeTodayValue)
		{
			stlCalcHistory();
			
			if (stlHistoryCount>0)
			{
				var value = stlHistorySum/stlHistoryCount;	// active calories per day (over the history sample)
				
				if ((stlAverage<=0) ||										// no stored rolling average yet
					((updateTimeTodayValue-stlAverageUpdate)>=60*1440*7))	// or more than 7 days since it was last updated
				{
					stlAverage = value;
				}
				else
				{
					stlAverage = stlAverage*(1.0-0.02) + value*0.02;
				}
			}

			stlAverageUpdate = updateTimeTodayValue;
		}
	}
	
	function updateSmartTrainingLoad(secsBetween, activityMonitorInfo, timeNowInMinutesToday, currentYear)
	{
		//updateTimeNowValue = timeNow.value();
		//updateTimeTodayValue = Time.today().value();

		// last update (every 10 mins?)
		// calories for last 4 days
		// long term training load
		//
		// new day - combine last day into long term and reset it
		// Scale by 0.96 and add new?
		// 0.96 gives 25% for last week
		// 19% for 2nd week
		// 14% for 3rd week
		// 10% for 4th week
		// 8%
		// 6%
		// 4%
		// 3%
		// 0.96^56=0.10
		//
		// 0.97 gives 20% to current week
		// 4% to week 8
		// 0.97^56=0.19
		//
		// 0.98 gives 14% to current week
		// 5% to week 8
		// 0.98^56=0.32
		//
		// 0.99 gives 9% to current week
		// 4% to week 8
		// 0.99^56=0.57
		//
		// today (extrapolated) * 5
		// yesterday * 5
		// -2 * 4
		// -3 * 3
		//
		// calculate a percentage 60% to 140% ?

		var count = 1.0;
		var sum = getActiveCalories(activityMonitorInfo.calories, timeNowInMinutesToday);		// active calories

		stlCalcHistory();		// update history data which is used for todays calculation
		
		if (stlHistoryCount>0)
		{
//var ttt = 400;
//count = ttt*0.8;
//sum = 1000*ttt/1440.0 + (stlHistorySum*(1440-ttt))/(stlHistoryCount*1440.0);
//sum *= count;

			// scale up our active calories so far today towards how many we would expect recently for the entire day 
			var value = stlHistorySum/stlHistoryCount;	// active calories per day (over the history sample)
			if (sum < value)
			{
				sum = (sum*timeNowInMinutesToday + value*(1440-timeNowInMinutesToday))/1440.0;
			}

			count = timeNowInMinutesToday*0.8;
			sum *= count;

			sum += stlHistorySum;
			count += stlHistoryCount;

			// DONT need to do this as average is calulated elsewhere now - it is just scaling up both sum and count the same amount
			// average in rest of today based on sum so far
			//var restOfToday = (1440-timeNowInMinutesToday)*0.8;
			//sum += (sum * restOfToday) / count;
			//count += restOfToday; 

			//var restOfToday = (1440-timeNowInMinutesToday)*0.8;
			//sum += (stlHistorySum * restOfToday) / stlHistoryCount;
			//count += restOfToday; 
		}
		
		if (count>0 && stlAverage>0)
		{
			stlTrainingLoad = sum/(count*stlAverage);
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
	// 8==dawn today, 9==dusk today, 10==sun rises at all today?
	// 11==dawn tomorrow, 12==dusk tomorrow, 13==sun rises at all tomorrow?
	// 14==next dawn/dusk, 15==next dawn/dusk is rise?
	var sunTimes = new[16];		// hour*60 + minute

	// For astronomical twilight the sun centre is 18 degrees below the horizon (instead of 0.83 for sunrise)

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
		var timeNowInMinutesToday = dateInfoShort.hour*60 + dateInfoShort.min;
		calculateSunNext(0, timeNowInMinutesToday);
		calculateSunNext(8, timeNowInMinutesToday);

		//System.println("sunTimes=" + sunTimes.toString());
	}

	function calculateSunNext(offset, timeNowInMinutesToday)
	{
		var sunNew6 = null;				// assume don't know time of next sun event
		var sunNew7 = !sunTimes[offset+2];		// and if the sun rises today then next event is sunset (or if it doesn't rise then sunset)
		
		var sunTimes0 = sunTimes[offset/*+0*/]; 
		if (sunTimes0!=null && timeNowInMinutesToday<sunTimes0)	// before sunrise?
		{
			sunNew6 = sunTimes0;
			sunNew7 = true;			// sunrise
		}
		else
		{
			var sunTimes1 = sunTimes[offset+1]; 
			if (sunTimes1!=null)		// sunset occurs today
			{
				if (timeNowInMinutesToday<sunTimes1)		// before sunset?
				{
					sunNew6 = sunTimes1;
					sunNew7 = false;	// sunset
				}
				else
				{
					var sunTimes3 = sunTimes[offset+3];
					if (sunTimes3!=null && timeNowInMinutesToday<sunTimes3)		// before sunrise tomorrow?
					{
						sunNew6 = sunTimes3;
						sunNew7 = true;		// sunrise
					}
				}
			}
		}

		sunTimes[offset+6] = sunNew6;
		sunTimes[offset+7] = sunNew7;
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

		var w2 = Math.cos(latRadians)*cosDeclination;

		// days since jan1st2000NoonUTC
		var jTransit = jStar + 0.0053*Math.sin(mRadians) - 0.0069*Math.sin(lambda*toRadians*2);
		jTransit -= UTC2TT;		// convert back to UTC time
			
		//var durationTransit = gregorian.duration({:seconds => jTransit*24*60*60});
		//var momentTransit = jan1st2000NoonUTC.add(durationTransit);
		//printMoment(momentTransit, "momentTransit");
		
		for (var dd=0; dd<=8; dd+=8)
		{
			var dayOffset3 = dayOffset*3 + dd;
			var sunHorizonAngle = ((dd==0) ? -0.83 : (propDawnDuskMode*-6.0));	// -0.83 is the suns radius, -18.0 is the angle for astronomical twilight
	
			var w1 = Math.sin((sunHorizonAngle - altAdjust)*toRadians) - Math.sin(latRadians)*sinDeclination;		// with height adjust
	
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
			
			if (cosW < -1.0 /*permanent day*/ || cosW > 1.0 /*permanent night*/)
			{
				sunTimes[dayOffset3] = null;
				sunTimes[dayOffset3 + 1] = null;
				sunTimes[dayOffset3 + 2] = (cosW < -1.0);
			}
			else
			{		
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

	// 0==sunrise, 1==sunset, 2==next sun event
	function getSunDisplayString(sunType, dateInfoShort, wantMinutes, use24Hour, addLeadingZero, sunOffset)
	{	
		calculateSun(dateInfoShort);

		var t = null;
		if (sunType==2)			// next sun event?
		{
			t = sunTimes[sunOffset+6];	// null or time of next sun event
		}
		else
		{
			// sunrise or sunset today
			t = ((sunType==0) ? sunTimes[sunOffset+0] : sunTimes[sunOffset+1]);
		}
												
		var eStr;
		if (t!=null)
		{
			t += 24*60;		// add 24 hours to make sure it is a positive number (if sunrise was before midnight ...) 
			if (wantMinutes)
			{
				eStr = (t%60).format("%02d");		// minutes
			}
			else
			{
				eStr = formatHourForDisplayString((t/60)%24, use24Hour, addLeadingZero);		// hours
			}
		}
		else
		{
			eStr = "--";
		}
		
		return eStr;
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
	//const PROFILE_START_DAWN = 0x0100;
	//const PROFILE_START_DUSK = 0x0200;
	//const PROFILE_END_DAWN = 0x0400;
	//const PROFILE_END_DUSK = 0x0800;

	(:m2face)
	var profileTimeData;

	// face memory data format:
	//
	// 0 number x PROFILE_NUM_USER*6 = profileTimeData array
	//
	// 1 boolean = positionGot
	// 2 float = positionLatitude  
	// 3 float = positionLongitude  
	// 4 float = positionAltitude
	//  
	// 5 number = profileActive
	// 6 number = profileDelayEnd
	//
	// 7 number = profileRandom
	// 8 number = profileRandomEnd
	//
	// 9 boolean = demoProfilesOn
	// 10 number = demoProfilesCurrentProfile
	// 11 number = demoProfilesCurrentEnd
	//
	// 12 number = honesty count (or -1 if disabled)
	//
	(:m2face)
	function loadMemoryData(timeNowValue)
	{
		var memData = applicationStorage.getValue(0);
		if (memData!=null && (memData instanceof Array))
		{
			if (memData.size()>1)
			{
				profileTimeData = memData[0];

				// testing code to convert 6 number format to 2 number format to reduce size from 735 bytes
				// this code uses up 270 bytes
				//var temp = new[24/*PROFILE_NUM_USER*/*2];
				//for (var i=0; i<24/*PROFILE_NUM_USER*/; i++)
				//{
				//	var i2 = i*2;
				//	var i6 = i*6;
				//	temp[i2+0] = (profileTimeData[i6+0]&0x7fff) | ((profileTimeData[i6+1]&0x7fff)<<16);
				//	temp[i2+1] = (profileTimeData[i6+2]&0xff) | ((profileTimeData[i6+3]&0xff)<<8) | ((profileTimeData[i6+4]&0xff)<<16) | ((profileTimeData[i6+5]&0xff)<<24);
				//}
				//temp = null;
			}
			
			positionGot = getBooleanFromArray(memData, 1);
			positionLatitude = getFloatFromArray(memData, 2);
			positionLongitude = getFloatFromArray(memData, 3);
			positionAltitude = getFloatFromArray(memData, 4);

			var profileNumber;
			var profileEnd;
	
			profileNumber = getNumberFromArray(memData, 5);
			profileEnd = getNumberFromArray(memData, 6);
			if (profileNumber>=0 && profileNumber<(24/*PROFILE_NUM_USER*/+PROFILE_NUM_PRESET))
			{
				profileActive = profileNumber;
				// verify that profileDelayEnd is not too far in the future ... just in case (should be 2+1 minutes or less)
				profileDelayEnd = ((profileEnd <= (timeNowValue + (2+1)*60)) ? profileEnd : 0);
			}
	
			profileNumber = getNumberFromArray(memData, 7);
			profileEnd = getNumberFromArray(memData, 8);
			if (profileNumber>=0 && profileNumber<(24/*PROFILE_NUM_USER*/+PROFILE_NUM_PRESET))
			{
				profileRandom = profileNumber;
				// verify that profileRandomEnd is not too far in the future ... just in case (should be 20+1 minutes or less)
				profileRandomEnd = ((profileEnd <= (timeNowValue + (20+1)*60)) ? profileEnd : 0);
			}
	
			demoProfilesOn = getBooleanFromArray(memData, 9);
			profileNumber = getNumberFromArray(memData, 10);
			profileEnd = getNumberFromArray(memData, 11);
			if (profileNumber>=0 && profileNumber<(24/*PROFILE_NUM_USER*/+PROFILE_NUM_PRESET))
			{
				demoProfilesCurrentProfile = profileNumber;
				// verify that demoProfilesCurrentEnd is not too far in the future ... just in case (should be 5+1 minutes or less)
				demoProfilesCurrentEnd = ((profileEnd <= (timeNowValue + (5+1)*60)) ? profileEnd : 0);
			}
			
			//var betaValue = getNumberFromArray(memData, 12);
			
			stlAverage = getFloatFromArray(memData, 13);
			stlAverageUpdate = getNumberFromArray(memData, 14);
		}

		if (profileTimeData==null || !(profileTimeData instanceof Array) || profileTimeData.size()!=(24/*PROFILE_NUM_USER*/*6))
		{
			profileTimeData = new[24/*PROFILE_NUM_USER*/*6];	// 144
			for (var i=0; i<(24/*PROFILE_NUM_USER*/*6); i++)
			{
				profileTimeData[i] = 0;
			}
		}

//		var charArray = propertiesGetCharArray("sd");
//		valDecodeArray(profileTimeData, 24/*PROFILE_NUM_USER*/*6, charArray, charArray.size());
//		//System.println("profileTimeData=" + profileTimeData.toString());
	
//		positionGot = propertiesGetBoolean("pg");
//		positionLatitude = propertiesGetFloat("la"); 
//		positionLongitude = propertiesGetFloat("lo");
//		positionAltitude = propertiesGetFloat("al");
//
//		var profileNumber;
//		var profileEnd;
//
//		profileNumber = propertiesGetNumber("ap");
//		profileEnd = propertiesGetNumber("ae");
//		if (profileNumber>=0 && profileNumber<(24/*PROFILE_NUM_USER*/+PROFILE_NUM_PRESET))
//		{
//			profileActive = profileNumber;
//			// verify that profileDelayEnd is not too far in the future ... just in case (should be 2+1 minutes or less)
//			profileDelayEnd = ((profileEnd <= (timeNowValue + (2+1)*60)) ? profileEnd : 0);
//		}
//
//		profileNumber = propertiesGetNumber("rp");
//		profileEnd = propertiesGetNumber("re");
//		if (profileNumber>=0 && profileNumber<(24/*PROFILE_NUM_USER*/+PROFILE_NUM_PRESET))
//		{
//			profileRandom = profileNumber;
//			// verify that profileRandomEnd is not too far in the future ... just in case (should be 20+1 minutes or less)
//			profileRandomEnd = ((profileEnd <= (timeNowValue + (20+1)*60)) ? profileEnd : 0);
//		}
//
//		demoProfilesOn = propertiesGetBoolean("do");
//		profileNumber = propertiesGetNumber("dp");
//		profileEnd = propertiesGetNumber("de");
//		if (profileNumber>=0 && profileNumber<(24/*PROFILE_NUM_USER*/+PROFILE_NUM_PRESET))
//		{
//			demoProfilesCurrentProfile = profileNumber;
//			// verify that demoProfilesCurrentEnd is not too far in the future ... just in case (should be 5+1 minutes or less)
//			demoProfilesCurrentEnd = ((profileEnd <= (timeNowValue + (5+1)*60)) ? profileEnd : 0);
//		}
	}
	
	(:m2face)
	function saveMemoryData()
	{
		var memData = [
			profileTimeData,				// 0
			positionGot,					// 1
			positionLatitude,				// 2
			positionLongitude,				// 3
			positionAltitude,				// 4
			profileActive,					// 5
			profileDelayEnd,				// 6
			profileRandom,					// 7
			profileRandomEnd,				// 8
			demoProfilesOn,					// 9
			demoProfilesCurrentProfile,		// 10
			demoProfilesCurrentEnd,			// 11
			-1,								// 12 (beta marker)
			stlAverage,						// 13
			stlAverageUpdate,				// 14
		];
		applicationStorage.setValue(0, memData);

//		var tempCharArray = new[24/*PROFILE_NUM_USER*/*6*2];	// 288
//		valEncodeArray(profileTimeData, 24/*PROFILE_NUM_USER*/*6, tempCharArray, 24/*PROFILE_NUM_USER*/*6*2);
//		applicationProperties.setValue("sd", StringUtil.charArrayToString(tempCharArray));

//		applicationProperties.setValue("pg", positionGot);
//		applicationProperties.setValue("la", positionLatitude);
//		applicationProperties.setValue("lo", positionLongitude);
//		applicationProperties.setValue("al", positionAltitude);
//
//		applicationProperties.setValue("ap", profileActive);
//		applicationProperties.setValue("ae", profileDelayEnd);
//
//		applicationProperties.setValue("rp", profileRandom);
//		applicationProperties.setValue("re", profileRandomEnd);
//
//		applicationProperties.setValue("do", demoProfilesOn);
//		applicationProperties.setValue("dp", demoProfilesCurrentProfile);
//		applicationProperties.setValue("de", demoProfilesCurrentEnd);
	}

	// app memory data format
	// boolean = positionGot
	// float = positionLatitude  
	// float = positionLongitude  
	// float = positionAltitude  

	(:m2app)
	function loadMemoryData(timeNowValue)
	{
		var memData = applicationStorage.getValue(0);
		if (memData!=null && (memData instanceof Array))
		{
			positionGot = getBooleanFromArray(memData, 0);
			positionLatitude = getFloatFromArray(memData, 1);
			positionLongitude = getFloatFromArray(memData, 2);
			positionAltitude = getFloatFromArray(memData, 3);
		}
	
//		positionGot = propertiesGetBoolean("pg");
//		positionLatitude = propertiesGetFloat("la"); 
//		positionLongitude = propertiesGetFloat("lo");
//		positionAltitude = propertiesGetFloat("al");
	}
	
	(:m2app)
	function saveMemoryData()
	{
		var memData = [positionGot, positionLatitude, positionLongitude, positionAltitude];
		applicationStorage.setValue(0, memData);

//		applicationProperties.setValue("pg", positionGot);
//		applicationProperties.setValue("la", positionLatitude);
//		applicationProperties.setValue("lo", positionLongitude);
//		applicationProperties.setValue("al", positionAltitude);
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

	//const GFX_VERSION_0 = 0;
	//const GFX_VERSION = 1;			// a version number
	
	//const MAX_GFX_DATA = 500;

	var gfxNum = 0;
	var gfxData = new[500/*MAX_GFX_DATA*/];

	(:m2app)
	function getUsedGfxData()
	{
		return gfxNum.toFloat()/500/*MAX_GFX_DATA*/;
	}

	//const MAX_GFX_CHARS = 150;

	var gfxCharArray = new[150/*MAX_GFX_CHARS*/];
	var gfxCharArrayLen = 0;

	(:m2app)
	function getUsedCharArray()
	{
		return gfxCharArrayLen.toFloat()/150/*MAX_GFX_CHARS*/;
	}

//	function valEncodeCharOld(v)
//	{
//		var c;
//		if (v<10)
//		{
//			c = 48+v;
//		}
//		else if (v<36)
//		{
//			c = 65-10+v;
//		}
//		else //if (v<62)
//		{
//			c = 97-36+v;
//		}
//
//		return c.toChar();
//	}		
	
//	function valDecodeCharOld(c)
//	{
//		var v = c.toNumber();
//		if (v>=97)
//		{
//			v -= (97-36);
//		}
//		else if (v>=65)
//		{
//			v -= (65-10);
//		}
//		else //if (v>=48)
//		{
//			v -= 48;
//		}
//	
//		return v;
//	}		
	
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
			c = ((v<0) ? 48 : (48+v));
		}
		else if (v<36)
		{
			c = 65-10+v;
		}
		else //if (v<62)
		{
			c = ((v<62) ? (97-36+v) : (97-36+61));
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

		if (isOldVersion0)
		{					
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
		}
		else
		{		
			if (v>=97)
			{
				v = ((v>(97-36+61)) ? 61 : (v-(97-36)));
			}
			else if (v>=65)
			{
				v = v-(65-10);
			}
			else //if (v>=48)
			{
				v = ((v>48) ? (v-48) : 0);
			}
		}
				
		return v;
	}		
	
//	(:m2face)
//	function valEncodeArray(arr, arrSize, charArray, charArraySize)
//	{
//		for (var i=0; i<arrSize; i++)
//		{
//			// 0-9 a-z A-Z
//			// 10 +26 +26 =62
//			// 62*62=3844, so 0-3843
//			
//			var val = arr[i];
//			if (val==null)
//			{
//				val = 0;
//			}
//			
//			var v0 = val/62;
//			var v1 = val%62;
//			
//			charArray[i*2] = valEncodeChar(v0);
//			charArray[i*2 + 1] = valEncodeChar(v1);
//		}
//	}

//	(:m2face)
//	function valDecodeArray(arr, arrSize, charArray, charArraySize)
//	{
//		for (var i=0; i<arrSize; i++)
//		{
//			var v0 = 0;
//			var v1 = 0;
//			
//			var i2 = i*2;
//			if (i2 < charArraySize-1)
//			{
//				v0 = valDecodeChar(charArray[i2]);
//				v1 = valDecodeChar(charArray[i2+1]);
//			}
//			
//			arr[i] = v0*62 + v1;
//		}
//	}

	(:m2app)
	function gfxToCharArray()
	{
		var charArray = new[510/*MAX_PROFILE_STRING_LENGTH*/];
		var charArrayLen = 0;
	
		//System.println("gfxNum=" + gfxNum);

		for (var index=0; index<gfxNum; )
		{
			//var id = getGfxId(index);
			var id = (gfxData[index] & 0x0F);	// cheaper with no function call in loop
		
			var curLen = charArrayLen;
		
			//var saveSize = gfxSizeSave(id);
			if (id<0 || id>=10/*GFX_SIZE_NUM*/)
			{
				break;
			}
			var saveSize =  gfxSizeArray[id + 10/*GFX_SIZE_NUM*/];	// cheaper with no function call in loop
			for (var i=0; i<saveSize; i++)
			{
				var val = gfxData[index+i] & 0xFFFF;
				
				// 0-9 a-z A-Z
				// 10 +26 +26 =62
				// 62*62=3844, so 0-3843				
				// but use the top bit to indicate if it is 1 or 2 bytes (so half that range is 0-1921 = 0x781)
				
				//System.print("" + val);

				if (val<31)
				{
					if (curLen<510/*MAX_PROFILE_STRING_LENGTH*/)
					{
						charArray[curLen] = valEncodeChar(val);
						//System.print("[" + c.toString() + "], ");
					}
					curLen++;
				}
				else
				{
					if (curLen<(510/*MAX_PROFILE_STRING_LENGTH*/-1))
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
			if (curLen<=510/*MAX_PROFILE_STRING_LENGTH*/)
			{
				charArrayLen = curLen;
				
				//index += gfxSize(id);
				//if (id<0 || id>=10/*GFX_SIZE_NUM*/)	this is checked above already
				//{
				//	break;
				//}
				index += gfxSizeArray[id]; 	// cheaper with no function call in loop
			}
			else
			{
				break;	// not space to add more				
			}
		}

		//System.println("");
		
		return charArray.slice(0, charArrayLen);
	}

	var isOldVersion0 = false;

	function gfxFromCharArray(charArray)
	{
		var gotError = false;
		var charArraySize = charArray.size();

		gfxNum = 0;

//System.println("start");

		// check for old GFX_VERSION to update to new format
		isOldVersion0 = (charArraySize>=2 && valDecodeChar(charArray[1])==0 && (valDecodeChar(charArray[0])&0x0F)==0/*GFX_VERSION_0*/);		// old version 0 (and header at start)
		if (isOldVersion0)
		{
			charArray[1] = valEncodeChar(1);	// set version 1
		}

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
					id = (v & 0x0F);

					if (isOldVersion0)
					{
						// recombine the id and visibility in new smaller format
						v = (((v>>8) & 0x1F) << 4) | id;
					}
//System.println("id=" + id);

					//itemSize = gfxSize(id);		// total item size in gfxData array
					if (id<0 || id>=10/*GFX_SIZE_NUM*/)
					{
//System.println("error1");
						gotError = true;
						break; 
					}
					itemSize = gfxSizeArray[id]; 	// cheaper with no function call in loop
					
					//saveSize = gfxSizeSave(id);	// number of bytes to read from saved data
					saveSize = gfxSizeArray[id + 10/*GFX_SIZE_NUM*/];	// cheaper with no function call in loop

					if (itemSize<=0)
					{
//System.println("error2");
						gotError = true;
						break; 
					}
					
					// check the size of this item will fit into the gfxData array
					if (gfxNum+itemSize > 500/*MAX_GFX_DATA*/)
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
			gfxResetToHeader();	
		}

		//System.println("");
	}

	function getGfxId(index)
	{
		return (gfxData[index] & 0x0F);
	}

	//const GFX_SIZE_NUM = 10;
	var gfxSizeArray = new[10/*GFX_SIZE_NUM*/*2]b;

	function gfxSize(id)
	{
		return ((id<0 || id>=10/*GFX_SIZE_NUM*/) ? 0 : gfxSizeArray[id]); 
	}

	function gfxSizeSave(id)
	{
		return ((id<0 || id>=10/*GFX_SIZE_NUM*/) ? 0 : gfxSizeArray[id + 10/*GFX_SIZE_NUM*/]);
	}

	// gfxAddHeader
	function gfxResetToHeader()
	{
		gfxData[0] = 0;		// id for header
		gfxData[1] = 1/*GFX_VERSION*/;	// version
		gfxData[2] = displaySize;	// watch display size
		gfxData[3] = 0+2/*COLOR_SAVE*/;	// background color
		gfxData[4] = 3+2/*COLOR_SAVE*/;	// foreground color
		gfxData[5] = 0+2/*COLOR_SAVE*/;	// menu color
		gfxData[6] = 3+2/*COLOR_SAVE*/;	// menu border
		gfxData[7] = -1/*COLOR_FOREGROUND*/+2/*COLOR_SAVE*/;	// field highlight
		gfxData[8] = -1/*COLOR_FOREGROUND*/+2/*COLOR_SAVE*/;	// element highlight
		gfxData[9] = 1;	// kerning off for large fonts (0x01) and dawn/dusk mode (0x06)
    	gfxData[10] = 75;	// propBatteryHighPercentage, 0 to 100
    	gfxData[11] = 25;	// propBatteryLowPercentage, 0 to 100
		gfxData[12] = 24; 	// prop2ndTimeZoneOffset, 0x3F (0 to 48, 24==0), 0x1C (0 to 6, 0==0, 1==15, 2==30, 3==45, 4==0, 5==-45, 6=-30, 7=-15 ((x+4)%8)-4)
		gfxData[13] = 1;	// propMoveBarAlertTriggerLevel, 1 to 5
		gfxData[14] = 0; 	// propFieldFontSystemCase (0=any, 1=upper, 2=lower)
		gfxData[15] = 1;	// propFieldFontUnsupported (0=xtiny to 4=large)
		//gfxData[index+9] = 0;	// default field font

		gfxNum = gfxSize(0);		// 16 
	}

	// seconds, ring, hour, minute, icon, field
	//const MAX_DYNAMIC_RESOURCES = 30;
	//const BUFFER_RESOURCE = 0x8FFFFFFF;
	
	var dynResNum = 0;
	var dynResList = new[30/*MAX_DYNAMIC_RESOURCES*/];
	var dynResResource = new[30/*MAX_DYNAMIC_RESOURCES*/];

	(:m2app)
	function getUsedDynamicResourceNum()
	{
		return dynResNum.toFloat()/30/*MAX_DYNAMIC_RESOURCES*/;
	}

	//const MAX_DYNAMIC_MEM = 500;
	var dynResMem50 = 0;
	var dynResMemFailed = false;

	(:m2app)
	function getUsedResourceMemory()
	{
		return (dynResMemFailed ? 1.0 : (dynResMem50.toFloat()/500/*MAX_DYNAMIC_MEM*/));
	}

	function addDynamicResource(r, m)
	{
		var i = dynResList.indexOf(r);
		if (i>=0)
		{
			return i;
		}
	
		if (dynResNum<30/*MAX_DYNAMIC_RESOURCES*/)
		{
			if ((dynResMem50+m)<=500/*MAX_DYNAMIC_MEM*/)
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
		
		return 30/*MAX_DYNAMIC_RESOURCES*/;
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
		propSecondResourceIndex = 30/*MAX_DYNAMIC_RESOURCES*/;
		propSecondPositionsIndex = 30/*MAX_DYNAMIC_RESOURCES*/;
		propSecondBufferIndex = 30/*MAX_DYNAMIC_RESOURCES*/;
		propSecondGfxIndex = -1;
    }

    function loadDynamicResources(dc)
    {
//		var prevMem = System.getSystemStats().freeMemory; 
//		System.println("loadDynamicResources free=" + prevMem);
    
    	var propSecondTextBufferIndex = -1;
    	
		for (var i=0; i<dynResNum; i++)
		{
			var r = dynResList[i];
			if (r==0x8FFFFFFF/*BUFFER_RESOURCE*/)
			{
		        // If this device supports BufferedBitmap, allocate the buffer for what's behind the seconds indicator 
		        //if (Toybox.Graphics has :BufferedBitmap)
				// This full color buffer is needed because anti-aliased fonts cannot be drawn into a buffer with a reduced color palette

				if (propSecondTextMode!=0)
				{
					propSecondTextBufferIndex = i; 
				}
				else
				{	
					dynResResource[i] = new Graphics.BufferedBitmap({:width=>62/*BUFFER_SIZE*/, :height=>62/*BUFFER_SIZE*/});
				}
			}
			else
			{
				dynResResource[i] = (isDynamicResourceSystemFont(r) ? r : WatchUi.loadResource(r));
			}

//	    	var curMem = System.getSystemStats().freeMemory; 
//	    	System.println("" + i + " = " + (prevMem-curMem) + " (" + ((prevMem-curMem+49)/50) + ")");
//	    	prevMem = curMem;
		}
		
		if (propSecondGfxIndex>=0)
		{
			if (propSecondTextMode!=0)
			{
				var dynamicResource = getDynamicResourceFromGfx(propSecondGfxIndex+2/*string_font*/);	// also 2/*large_font*/ is the same luckily
				if (dynamicResource!=null)
				{
					bufferW = dc.getTextWidthInPixels("0", dynamicResource)*2;		// w
					bufferH = dc.getFontAscent(dynamicResource);					// h
				
					// allocate the buffer, which depends on the size of font used
					if (propSecondTextBufferIndex>=0)
					{
						// seems to be approximately width * height + 200 bytes
						// then round up to nearest 50 block
						var m = (bufferW*bufferH + 200 + 49)/50;
						if ((dynResMem50+m)<=500/*MAX_DYNAMIC_MEM*/)
						{
							dynResMem50 += m;
							dynResResource[propSecondTextBufferIndex] = new Graphics.BufferedBitmap({:width=>bufferW, :height=>bufferH});
						}
						else
						{
							dynResMemFailed = true;
						}
					}
				}
			}
			else
			{
				// seconds indicator
				// build the seconds color array only after the seconds refresh has been set and the position array has been loaded
				var dynamicPositions = getDynamicResource(propSecondPositionsIndex);
				propSecondAligned = (dynamicPositions==null || outerAlignedToSeconds(dynamicPositions));
				buildSecondsColorArray(propSecondGfxIndex);
			}
		}
    }
    
	function getDynamicResource(i)
	{
		return ((i<dynResNum) ? dynResResource[i] : null);
	}

	function getDynamicResourceFromGfx(gfxIndex)
	{
		var resourceIndex = ((gfxData[gfxIndex] >> 16) & 0xFF);
		return ((resourceIndex<dynResNum) ? dynResResource[resourceIndex] : null);
	}

//	function getDynamicResourceAscent(i)
//	{
//		return ((i<dynResNum) ? Graphics.getFontAscent(dynResResource[i]) : 0);
//	}

//	function getDynamicResourceDescent(i)
//	{
//		return ((i<dynResNum) ? Graphics.getFontDescent(dynResResource[i]) : 0);
//	}

	function updateFieldMaxAscentDescentResource(gfxIndex, font)
	{
		var ascent = Graphics.getFontAscent(font);
		var descent = Graphics.getFontDescent(font);

		// limit the size of system number fonts (as they can be way off compared to real number sizes)
		if ((font instanceof Number) && font>=Graphics.FONT_SYSTEM_NUMBER_MILD && font<=Graphics.FONT_SYSTEM_NUMBER_THAI_HOT)
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

		updateFieldMaxAscentDescent(gfxIndex, ascent, descent);
	}

	function updateFieldMaxAscentDescent(gfxIndex, ascent, descent)
	{
		var a = (gfxData[gfxIndex]&0xFF);
		var d = ((gfxData[gfxIndex]&0xFF00) >> 8);
		
		a = getMinMax(ascent, a, displaySize);	// max ascent
		d = getMinMax(descent, d, displaySize);	// max descent
					
		gfxData[gfxIndex] = ((a&0xFF) | ((d&0xFF) << 8));
	}

    function isDynamicResourceSystemFont(font)
    {
    	return ((font!=null) && (font instanceof Number) && (font>=0) && (font<=Graphics.FONT_SYSTEM_NUMBER_THAI_HOT));
    }

	function gfxScalePositionSize(index, origSize)
	{
		// adjust sizes so they convert backwards & forwards to be the same (by adding 0.5)
		if (origSize!=displaySize) 
		{
			gfxData[index] = getMinMax((gfxData[index]*displaySize + origSize/2)/origSize, 0, displaySize);
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
			var fontId = fontList[fontIndex];
			var resourceIndex = addDynamicResource(fontId, dynResSizeArray[fontIndex]);
			if (resourceIndex>=0 && resourceIndex<dynResNum && dynResResource[resourceIndex]==null && isDynamicResourceSystemFont(fontId))
			{
				dynResResource[resourceIndex] = fontId;
			}
			return resourceIndex;
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
		
		propSecondGfxIndex = -1;
    	
		if (gfxNum>0 && getGfxId(0)==0)		// header - calculate values from this here so similar to gfxOnUpdate
		{
			origSize = getMinMax(gfxData[0+2], 218, 280);	// displaysize stored in gfx
			gfxData[0+2] = displaySize;	// everything will be updated to match the real displaysize of this watch

			propBackgroundColor = getColor64FromGfx(gfxMinMaxInPlace(0+3, 2/*COLOR_SAVE*/, 63+2/*COLOR_SAVE*/));	// propBackgroundColor
			propForegroundColor = getColor64FromGfx(gfxMinMaxInPlace(0+4, 2/*COLOR_SAVE*/, 63+2/*COLOR_SAVE*/));	// propForegroundColor

			// propMenuColor editor only
			// propMenuBorder editor only
			// propFieldHighlight editor only
			// propElementHighlight editor only

			gfxMinMaxInPlace(0+9, 0, 8);		// propKerningOn (0x01) and dawn/dusk mode (0x06) 
			propKerningOn = ((gfxData[0+9]&0x01)==0);
			propDawnDuskMode = ((gfxData[0+9]&0x06)>>1)%3 + 1;		// 1, 2, 3
			
			propBatteryHighPercentage = gfxMinMaxInPlace(0+10, 0, 100);				// 0 to 100
			propBatteryLowPercentage = gfxMinMaxInPlace(0+11, 0, 100);				// 0 to 100

			gfxMinMaxInPlace(0+12, 0, 511);		// prop2ndTimeZoneOffset, 0x3F (0 to 48, 24==0), 0x1C0 (0 to 6, 0==0, 1==15, 2==30, 3==45, 4==0, 5==-45, 6=-30, 7=-15 ((x+4)%8)-4)
			prop2ndTimeZoneOffset = ((gfxData[0+12]&0x03F)-24)*60 + (((((gfxData[0+12]&0x1C0)>>6)+4)%8)-4)*15;		// 0x3F (0 to 48, 24==0), 0x1C0 (0 to 6, 0==0, 1==15, 2==30, 3==45, 4==0, 5==-45, 6=-30, 7=-15 ((x+4)%8)-4)

			propMoveBarAlertTriggerLevel = gfxMinMaxInPlace(0+13, 1, 5);			// 1 to 5
			propFieldFontSystemCase = gfxMinMaxInPlace(0+14, 0, 2); 				// (0=any, 1=upper, 2=lower)
			propFieldFontUnsupported = gfxMinMaxInPlace(0+15, 0, 4);				// (0=xtiny to 4=large)
		}

		for (var index=0; index<gfxNum; )
		{
			//var id = getGfxId(index);
			var id = (gfxData[index] & 0x0F);	// cheaper with no function call in loop
			
			//if (id==0)	// header done above
			//{
			//}

			if (id==1)	// field
			{
				gfxScalePositionSize(index+1, origSize);	// x from left
				gfxScalePositionSize(index+2, origSize);	// y from bottom
			}
			else if (id==2 || id==3)	// large or string
			{ 
				var r = (gfxData[index+2/*string_font*/] & 0xFF);
				var fontListIndex;
				var eDisplay = (gfxData[index+1] & 0x7F);	// 0x80 is for useNumFont, 1/*large_type*/
				var setSecondTextMode = -1;
				
				if (id==2)		// large
				{
				 	if (r<0 || r>49)	// 0-9 (half fonts), 10-45 (s,m,l fonts), 46-49 (4 system number fonts)
				 	{
				 		r = 25/*m regular*/;
				 	}
				 	
				 	if (r<46)	// custom font
				 	{
				 		if (eDisplay==2/*BIG_COLON*/)		// colon
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

					if (eDisplay==22/*BIG_SECOND_CHEAP*/ || eDisplay==23/*BIG_SECOND_TRUE*/)
					{
						setSecondTextMode = eDisplay-22+1;		// 0=off, 1=cheap, 2=true
					}
				}
				else			// string
				{
				 	if (r<0 || r>19)	// 0-14 (s,m,l fonts), 15-19 (5 system fonts)
				 	{
				 		r = 7/*m regular*/;
				 	}
				 	var useNumFont = ((gfxData[index+1]&0x80)==0);
				 	fontListIndex = ((r<15) ? (r + (useNumFont?63:78)) : (r-15+0));

					if (eDisplay==62/*FIELD_SECOND_CHEAP*/ || eDisplay==63/*FIELD_SECOND_TRUE*/)
					{
						setSecondTextMode = eDisplay-62+1;		// 0=off, 1=cheap, 2=true
					}
				}			 	
			 	
				var resourceIndex = addDynamicResource(fontList[fontListIndex], dynResSizeArray[fontListIndex]);
				gfxData[index+2/*string_font*/] = r | ((resourceIndex & 0xFF) << 16);

				if (setSecondTextMode>=0)
				{
					propSecondTextMode = setSecondTextMode;		// 0=off, 1=cheap, 2=true
					propSecondGfxIndex = index;
					
					if (propSecondTextMode==2)	// true
					{
						propSecondBufferIndex = addDynamicResource(0x8FFFFFFF/*BUFFER_RESOURCE*/, 0);
					}
				}
			}
			else if (id==4 || id==5)	// icon or movebar
			{
				var r = (gfxData[index+2/*icon_font*/] & 0xFF);
			 	if (r<0 || r>1)
			 	{
			 		r = 0;
			 	}
				var resourceIndex = 30/*MAX_DYNAMIC_RESOURCES*/;
				if (id==5 || (gfxData[index+1]>=0/*FIELD_SHAPE_CIRCLE*/ && gfxData[index+1]<=32/*FIELD_SHAPE_MOUNTAIN*/))
				{
				 	var fontListIndex = r + 93;
					resourceIndex = addDynamicResource(fontList[fontListIndex], dynResSizeArray[fontListIndex]);
				}
				gfxData[index+2/*icon_font*/] = r | ((resourceIndex & 0xFF) << 16);
			}
//			else if (id==5)		// movebar
//			{
//				var r = (gfxData[index+2/*movebar_font*/] & 0xFF);
//			 	if (r<0 || r>1)
//			 	{
//			 		r = 0;
//			 	}
//			 	var fontListIndex = r + 93;
//				var resourceIndex = addDynamicResource(fontList[fontListIndex], dynResSizeArray[fontListIndex]);
//				gfxData[index+2/*movebar_font*/] = r | ((resourceIndex & 0xFF) << 16);
//			}			
//			else if (id==6)		// chart
//			{
//			}
			else if (id==7)		// rectangle
			{
				gfxScalePositionSize(index+4/*rect_x*/, origSize);	// x from left
				gfxScalePositionSize(index+5/*rect_y*/, origSize);	// y from bottom
				gfxScalePositionSize(index+6/*rect_w*/, origSize);	// width
				gfxScalePositionSize(index+7/*rect_h*/, origSize);	// height
			}
			else if (id==8)		// ring
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
			}
			else if (id==9)		// seconds
			{
				propSecondTextMode = 0;
				propSecondGfxIndex = index;
				
				var r = (gfxData[index+1] & 0x00FF);	// font
			 	if (r<0 || r>=25/*SECONDFONT_UNUSED*/)
			 	{
			 		r = 0/*SECONDFONT_TRI*/;
			 	}
			 	
			 	var outerListIndex = r*2;
				propSecondResourceIndex = addDynamicResource(outerList[outerListIndex], dynResOuterSizeArray[r]);
				propSecondPositionsIndex = addDynamicResource(outerList[outerListIndex+1], 7);
				
		    	propSecondRefreshStyle = ((gfxData[index+1] >> 8) & 0x03);	// refresh style
		    	if (propSecondRefreshStyle!=1/*REFRESH_EVERY_MINUTE*/)
		    	{
					propSecondBufferIndex = addDynamicResource(0x8FFFFFFF/*BUFFER_RESOURCE*/, 84);
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
			}
			
			//index += gfxSize(id);
			if (id<0 || id>=10/*GFX_SIZE_NUM*/)
			{
				break;
			}
			index += gfxSizeArray[id]; 	// cheaper with no function call in loop
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
    	
    	var ringAdjustIndex = (propSecondAligned ? 0 : 59);
    	
    	for (var i=0; i<60; i++)
    	{
			var col;
	
			if (secondColorIndex0!=(-2/*COLOR_NOTSET*/+2/*COLOR_SAVE*/) && i==0)
			{
				col = secondColorIndex0;
			}
			else if (secondColorIndex15!=(-2/*COLOR_NOTSET*/+2/*COLOR_SAVE*/) && (i%15)==0)
			{
				col = secondColorIndex15;
			}
			else if (secondColorIndex10!=(-2/*COLOR_NOTSET*/+2/*COLOR_SAVE*/) && (i%10)==0)
			{
				col = secondColorIndex10;
			}
			else if (secondColorIndex5!=(-2/*COLOR_NOTSET*/+2/*COLOR_SAVE*/) && (i%10)==5)
			{
				col = secondColorIndex5;
			}
	        else
	        {
	        	col = secondColorIndex;		// second color
	        }
	        
	        propSecondColorIndexArray[(i+ringAdjustIndex)%60] = col;
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
		return (((((t!=null) ? t : 0) + 12 + 48*60 - timeOffsetInMinutes) * drawRange) / (24*60) + segmentAdjust + drawRange)%drawRange;
	}

	function editorCheckGfxVisibility(index)
	{
		return true;
	}

	function dayNumberOfWeek(dateInfoShort)
	{
		return (((dateInfoShort.day_of_week - updateFirstDayOfWeek + 7) % 7) + 1);		// 1-7
	}

	var updateTimeNowValue;
	var updateTimeTodayValue;
	var updateTimeZoneOffset;

    var updateBatteryLevel;
    var updateNotificationCount;
    var updateFirstDayOfWeek;
	var updateIs24Hour;
	var updateTime2ndInMinutes;

	function gfxOnUpdate(dc, clockTime, timeNow)
	{
        var hour = clockTime.hour;
        var minute = clockTime.min;
        var second = clockTime.sec;
        var timeNowInMinutesToday = hour*60 + minute;

		//var systemStats = System.getSystemStats();				// 168 bytes, but uses less code memory
		updateBatteryLevel = System.getSystemStats().battery;

		//var hour2nd = (hour - clockTime.timeZoneOffset/3600 + prop2ndTimeZoneOffset + 48)%24;		// 2nd time zone
        updateTime2ndInMinutes = (timeNowInMinutesToday - clockTime.timeZoneOffset/60 + prop2ndTimeZoneOffset + 2*1440)%1440;
		var hour2nd = updateTime2ndInMinutes/60;

        var deviceSettings = System.getDeviceSettings();		// 960 bytes, but uses less code memory
    	updateNotificationCount = deviceSettings.notificationCount;
    	updateFirstDayOfWeek = deviceSettings.firstDayOfWeek;
		updateIs24Hour = deviceSettings.is24Hour;
	    var alarmCount = deviceSettings.alarmCount;
	    var phoneConnected = deviceSettings.phoneConnected;
        var doNotDisturb = deviceSettings.doNotDisturb;
		var activityTrackingOn = deviceSettings.activityTrackingOn;
		var distanceUnits = deviceSettings.distanceUnits;
		var elevationUnits = deviceSettings.elevationUnits;
		var temperatureUnits = deviceSettings.temperatureUnits;
		deviceSettings = null;
		
		var activityMonitorInfo = ActivityMonitor.getInfo();  	// 560 bytes, but uses less code memory
		
		var gregorian = Time.Gregorian;
		var dateInfoShort = gregorian.info(timeNow, Time.FORMAT_SHORT);
		var dateInfoMedium = gregorian.info(timeNow, Time.FORMAT_MEDIUM);
		
		// calculate fields to display
		var visibilityStatus = new[34/*STATUS_NUM*/];
		visibilityStatus[0/*STATUS_ALWAYSON*/] = true;
	    visibilityStatus[1/*STATUS_GLANCE_ON*/] = glanceActive;
	    visibilityStatus[2/*STATUS_GLANCE_OFF*/] = !glanceActive;
	    visibilityStatus[3/*STATUS_DONOTDISTURB_ON*/] = (hasDoNotDisturb && doNotDisturb);
	    visibilityStatus[4/*STATUS_DONOTDISTURB_OFF*/] = (hasDoNotDisturb && !doNotDisturb);
	    visibilityStatus[5/*STATUS_ALARM_ON*/] = (alarmCount > 0);
	    visibilityStatus[6/*STATUS_ALARM_OFF*/] = (alarmCount == 0);
	    visibilityStatus[7/*STATUS_NOTIFICATIONS_PENDING*/] = (updateNotificationCount > 0);
	    visibilityStatus[8/*STATUS_NOTIFICATIONS_NONE*/] = (updateNotificationCount == 0);
	    visibilityStatus[9/*STATUS_PHONE_CONNECTED*/] = phoneConnected;
	    visibilityStatus[10/*STATUS_PHONE_NOT*/] = !phoneConnected;
	    var lteState = lteConnected();
	    visibilityStatus[11/*STATUS_LTE_CONNECTED*/] = (hasLTE && lteState);
	    visibilityStatus[12/*STATUS_LTE_NOT*/] = (hasLTE && !lteState);
	    visibilityStatus[14/*STATUS_BATTERY_HIGH*/] = (updateBatteryLevel>=propBatteryHighPercentage);
	    visibilityStatus[16/*STATUS_BATTERY_LOW*/] = (!visibilityStatus[14/*STATUS_BATTERY_HIGH*/] && updateBatteryLevel<=propBatteryLowPercentage);
	    visibilityStatus[15/*STATUS_BATTERY_MEDIUM*/] = (!visibilityStatus[14/*STATUS_BATTERY_HIGH*/] && !visibilityStatus[16/*STATUS_BATTERY_LOW*/]);
	    visibilityStatus[13/*STATUS_BATTERY_HIGHORMEDIUM*/] = !visibilityStatus[16/*STATUS_BATTERY_LOW*/];
		// moveBarLevel 0 = not triggered
		// moveBarLevel has range 1 to 5
		// propFieldMoveAlarmTriggerTime has range 1 to 5
	    var moveBarAlertTriggered = (getNullCheckZero(activityMonitorInfo.moveBarLevel) >= propMoveBarAlertTriggerLevel); 
	    visibilityStatus[17/*STATUS_MOVEBARALERT_TRIGGERED*/] = (activityTrackingOn && moveBarAlertTriggered);
	    visibilityStatus[18/*STATUS_MOVEBARALERT_NOT*/] = (activityTrackingOn && !moveBarAlertTriggered);
	    visibilityStatus[19/*STATUS_AM*/] = (hour < 12);
	    visibilityStatus[20/*STATUS_PM*/] = (hour >= 12);
	    visibilityStatus[21/*STATUS_2ND_AM*/] = (hour2nd < 12);
	    visibilityStatus[22/*STATUS_2ND_PM*/] = (hour2nd >= 12);
	    //visibilityStatus[23/*STATUS_SUNEVENT_RISE*/] = null;		// calculated on demand
	    //visibilityStatus[24/*STATUS_SUNEVENT_SET*/] = null;		// calculated on demand
	    //visibilityStatus[25/*STATUS_DAWNDUSK_LIGHT*/] = null;		// calculated on demand
	    //visibilityStatus[26/*STATUS_DAWNDUSK_DARK*/] = null;		// calculated on demand
	    //visibilityStatus[27/*STATUS_HR_ZONE_0*/] = null;		// calculated on demand
	    //visibilityStatus[28/*STATUS_HR_ZONE_1*/] = null;		// calculated on demand
	    //visibilityStatus[29/*STATUS_HR_ZONE_2*/] = null;		// calculated on demand
	    //visibilityStatus[30/*STATUS_HR_ZONE_3*/] = null;		// calculated on demand
	    //visibilityStatus[31/*STATUS_HR_ZONE_4*/] = null;		// calculated on demand
	    //visibilityStatus[32/*STATUS_HR_ZONE_5*/] = null;		// calculated on demand
	    //visibilityStatus[33/*STATUS_HR_ZONE_6*/] = null;		// calculated on demand

		fieldActivePhoneStatus = null;
		fieldActiveNotificationsStatus = null;
		fieldActiveNotificationsCount = null;
		fieldActiveLTEStatus = null;
		
    	propSecondIndicatorOn = false;

		stlCheckAverage();

		var indexCurField = -1;
		var fieldVisible = false;
		
//		var indexPrevLargeWidth = -1;
//		var prevLargeNumber = -1;
//		var prevLargeFontKern = -1;
	
		var prevBatteryIndex = -1;
	
		gfxCharArrayLen = 0;
	
		for (var index=0; index<gfxNum; )
		{
			//var id = getGfxId(index);
			var id = (gfxData[index] & 0x0F);	// cheaper with no function call in loop
			var eVisible = ((gfxData[index] >> 4) & 0x3F);

			var isVisible = true;
			
			if (eVisible>=0 && eVisible<34/*STATUS_NUM*/)
			{
				// these fieldActiveXXXStatus flags need setting whether or not the field element using them is visible!!
				// So make sure to do these tests before the visibility test
				if (eVisible==7/*STATUS_NOTIFICATIONS_PENDING*/ || eVisible==8/*STATUS_NOTIFICATIONS_NONE*/)
				{
					fieldActiveNotificationsStatus = (updateNotificationCount > 0);
				} 
				else if (eVisible==9/*STATUS_PHONE_CONNECTED*/ || eVisible==10/*STATUS_PHONE_NOT*/)
				{
					fieldActivePhoneStatus = phoneConnected;
				} 
				else if (eVisible==11/*STATUS_LTE_CONNECTED*/ || eVisible==12/*STATUS_LTE_NOT*/)
				{
					fieldActiveLTEStatus = lteState;
				}

		    	if (visibilityStatus[eVisible]==null)
		    	{
			    	if (eVisible>=23/*STATUS_SUNEVENT_RISE*/ && eVisible<=26/*STATUS_DAWNDUSK_DARK*/)
			    	{
		    			calculateSun(dateInfoShort);
		    			
		    			var sunTimes7 = sunTimes[(eVisible>=25/*STATUS_DAWNDUSK_LIGHT*/) ? (7+8) : (7+0)];
						if (sunTimes7!=null)
						{
		    				visibilityStatus[eVisible] = ((((eVisible-23/*STATUS_SUNEVENT_RISE*/)%2)==0) ? sunTimes7 : !sunTimes7);
		    			}
			    	}
			    	else if (eVisible>=27/*STATUS_HR_ZONE_0*/ && eVisible<=33/*STATUS_HR_ZONE_6*/)
			    	{
						calculateHeartRate(minute, second);

						visibilityStatus[27/*STATUS_HR_ZONE_0*/] = ((heartDisplayLatest==null) || (heartDisplayLatest<=heartRateZones[0]));
						visibilityStatus[33/*STATUS_HR_ZONE_6*/] = ((heartDisplayLatest!=null) && (heartDisplayLatest>heartRateZones[5]));
						for (var z=1; z<=5; z++)
						{ 
							visibilityStatus[z+27/*STATUS_HR_ZONE_0*/] = (heartDisplayLatest!=null) && (heartDisplayLatest>heartRateZones[z-1] && (heartDisplayLatest<=heartRateZones[z]));
						}
					}
		    	}
		    	
		    	isVisible = (visibilityStatus[eVisible]!=null && visibilityStatus[eVisible]);
			}
			
			// remember visibility for this update
			if (isVisible)
			{
				gfxData[index] |= 0x10000;
			}
			else
			{
				gfxData[index] &= ~0x10000;

				if (isEditor)
				{
					isVisible = editorCheckGfxVisibility(index);
				}
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
					
					prevBatteryIndex = -1;

					break;
				}

				case 2:		// large (hour, minute, colon)
				case 3:		// string
				{
					if (!(fieldVisible && isVisible))
					{
						break;
					}

					gfxData[index+4] = 0;	// string start
					gfxData[index+5] = 0;	// string end
					gfxData[index+6] = 0;	// width

					var dynamicResource = getDynamicResourceFromGfx(index+2/*string_font*/);
					if (dynamicResource==null)
					{
						break;
					}

					var eStr = null;
					var eDisplay = (gfxData[index+1] & 0x7F);	// 0x80 is for useNumFont
					var makeUpperCase = false;
					var checkDiacritics = false;
					var useUnsupportedFont = false;
					
					if (id==2)		// large
					{
						//var narrowKern = false;
						//
						//var fontTypeKern = (gfxData[index+1] & 0xFF);
						//if (fontTypeKern>=6)
						//{
						//	if (fontTypeKern>=33 && fontTypeKern<=38)	// large italic
						//	{
						//		fontTypeKern -= 33;
						//	}
						//	else if (fontTypeKern>=39 && fontTypeKern<=56)	// large mono
						//	{
						//		fontTypeKern = (fontTypeKern - 39)%6;
						//	}
						//	else
						//	{
						//		fontTypeKern = -1;		// no kerning
						//	}
						//}

						//var cNum = c.toNumber();
						//if (indexPrevLargeWidth>=0 && prevLargeFontKern>=0 && fontTypeKern>=0)
						//{
						//	var k = getKern(prevLargeNumber - 48/*APPCHAR_0*/, cNum - 48/*APPCHAR_0*/, prevLargeFontKern, fontTypeKern, narrowKern);
						//	gfxData[indexPrevLargeWidth] -= k;
						//	gfxData[indexCurField+4] -= k;	// total width
						//}
						//
						//indexPrevLargeWidth = indexWidthJ;
						//prevLargeNumber = cNum;
						//prevLargeFontKern = fontTypeKern;
						//
						//// for last digit in current field (if it is large font)
						//if (j!=0)
						//{
						//	gfxData[indexCurField+5] = 0;	// remove existing x adjustment
						//	if (gfxData[indexCurField+3]==0)	// centre justification
						//	{
						//		//if (italic font)
						//		//{
						//		//	gfxData[indexCurField+5] += 1;	// shift right 1 pixel
						//		//}
						//		
						//		if ((cNum - 48/*APPCHAR_0*/) == 4)		// last digit is a 4 
						//		{
						//			gfxData[indexCurField+5] += 1;	// shift right 1 more pixel
						//		}
						//	}
						//}

						//0,		<!-- BIG_HOUR -->
						//3,		<!-- BIG_HOUR_0 -->
						//1,		<!-- BIG_MINUTE -->					
						//2,		<!-- BIG_COLON -->
						//4,		<!-- BIG_HOUR_1ST -->
						//5,		<!-- BIG_HOUR_2ND -->
						//6,		<!-- BIG_HOUR_0_1ST -->
						//7,		<!-- BIG_HOUR_0_2ND -->
						//8,		<!-- BIG_MINUTE_1ST -->
						//9			<!-- BIG_MINUTE_2ND -->
						//10,		<!-- BIG_HOUR_12 -->
						//11,		<!-- BIG_HOUR_12_1ST -->
						//12,		<!-- BIG_HOUR_12_2ND -->
						//13,		<!-- BIG_HOUR_12_0 -->
						//14,		<!-- BIG_HOUR_12_0_1ST -->
						//15,		<!-- BIG_HOUR_12_0_2ND -->
						//16,		<!-- BIG_HOUR_24 -->
						//17,		<!-- BIG_HOUR_24_1ST -->
						//18,		<!-- BIG_HOUR_24_2ND -->
						//19,		<!-- BIG_HOUR_24_0 -->
						//20,		<!-- BIG_HOUR_24_0_1ST -->
						//21		<!-- BIG_HOUR_24_0_2ND -->
						//22,		<!-- BIG_SECOND_CHEAP -->
						//23		<!-- BIG_SECOND_TRUE -->
	
						if (eDisplay==2/*BIG_COLON*/)
						{
							var r = (gfxData[index+2/*large_font*/] & 0xFF);
						 	if (r<10)	// 0-9 (half fonts), 10-45 (s,m,l fonts), 46-49 (4 system number fonts)
						 	{
								eStr = ((r%5) + 48).toChar().toString();
						 	}
						 	else if (r<46)
						 	{
								eStr = (((r-10)%6) + 48).toChar().toString();
						 	}
						 	else
						 	{
								eStr = ":";
						 	}
						}
						else if (eDisplay==1/*BIG_MINUTE*/ || eDisplay==8/*BIG_MINUTE_1ST*/ || eDisplay==9/*BIG_MINUTE_2ND*/)
						{
							eStr = minute.format("%02d");
							
							if (eDisplay!=1/*BIG_MINUTE*/)
							{
								eStr = eStr.substring(eDisplay-8/*BIG_MINUTE_1ST*/, eDisplay-8/*BIG_MINUTE_1ST*/+1);
							}
						}
						else if (eDisplay==22/*BIG_SECOND_CHEAP*/ || eDisplay==23/*BIG_SECOND_TRUE*/)
						{
							eStr = second.format("%02d");
							
							if (propSecondGfxIndex==index)
							{
								propSecondIndicatorOn = true;
							}
						}
						else // hours
						{
							//0,		<!-- BIG_HOUR -->
							//3,		<!-- BIG_HOUR_0 -->
							//4,		<!-- BIG_HOUR_1ST -->
							//5,		<!-- BIG_HOUR_2ND -->
							//6,		<!-- BIG_HOUR_0_1ST -->
							//7,		<!-- BIG_HOUR_0_2ND -->
	
							//10,		<!-- BIG_HOUR_12 -->
							//11,		<!-- BIG_HOUR_12_1ST -->
							//12,		<!-- BIG_HOUR_12_2ND -->
							//13,		<!-- BIG_HOUR_12_0 -->
							//14,		<!-- BIG_HOUR_12_0_1ST -->
							//15,		<!-- BIG_HOUR_12_0_2ND -->
							//16,		<!-- BIG_HOUR_24 -->
							//17,		<!-- BIG_HOUR_24_1ST -->
							//18,		<!-- BIG_HOUR_24_2ND -->
							//19,		<!-- BIG_HOUR_24_0 -->
							//20,		<!-- BIG_HOUR_24_0_1ST -->
							//21		<!-- BIG_HOUR_24_0_2ND -->
	
							var addLeadingZero = (eDisplay==3/*BIG_HOUR_0*/);
							var use24Hour = updateIs24Hour;
							var digit = -1;
							
							if (eDisplay>=4)
							{
								if (eDisplay>=10)
								{
									var tempType = eDisplay-10; 
									addLeadingZero = ((tempType%6)>=3);
									use24Hour = (tempType>=6);
									digit = (tempType%3) - 1;
								}
								else	// 4, 5, 6, 7
								{
									addLeadingZero = (eDisplay==6/*BIG_HOUR_0_1ST*/ || eDisplay==7/*BIG_HOUR_0_2ND*/);
									digit = ((eDisplay-4)%2);
								}
							}
							
							
							eStr = formatHourForDisplayString(hour, use24Hour, addLeadingZero);
							
							if (digit>=0)
							{
								digit -= (2-eStr.length());
								if (digit>=0)
								{
									eStr = eStr.substring(digit, digit+1);
								}
								else
								{
									eStr = null;
								}
							}
						}
					}
					else if (eDisplay>=64 && eDisplay<=103)		// string (time advanced)
					{
						//64 "hour12",
						//65 "hour24",
						//66 "hour 0#",
						//67 "hour12 0#",
						//68 "hour24 0#",
						//69 "2nd hour12",
						//70 "2nd hour24",
						//71 "2nd hour 0#",
						//72 "2nd hour12 0#",
						//73 "2nd hour24 0#",
						//74 "sunrise hour12",
						//75 "sunrise hour24",
						//76 "sunrise hour 0#",
						//77 "sunrise hour12 0#",
						//78 "sunrise hour24 0#",
						//79 "sunset hour12",
						//80 "sunset hour24",
						//81 "sunset hour 0#",
						//82 "sunset hour12 0#",
						//83 "sunset hour24 0#",
						//84 "next sun event\nhour12",
						//85 "next sun event\nhour24",
						//86 "next sun event\nhour 0#",
						//87 "next sun event\nhour12 0#",
						//88 "next sun event\nhour24 0#"
						//89 "dawn hour12",
						//90 "dawn hour24",
						//91 "dawn hour 0#",
						//92 "dawn hour12 0#",
						//93 "dawn hour24 0#",
						//94 "dusk hour12",
						//95 "dusk hour24",
						//96 "dusk hour 0#",
						//97 "dusk hour12 0#",
						//98 "dusk hour24 0#",
						//99 "next dawn/dusk\nhour12",
						//100 "next dawn/dusk\nhour24",
						//101 "next dawn/dusk\nhour 0#",
						//102 "next dawn/dusk\nhour12 0#",
						//103 "next dawn/dusk\nhour24 0#"

						var eTemp = eDisplay - 64/*FIELD_HOUR_12*/;
					
						var eTempMod5 = (eTemp%5);
						var use24Hour = ((eTempMod5==1) || (eTempMod5==4) || ((eTempMod5==2) && updateIs24Hour));
						var addLeadingZero = (eTempMod5>=2);
												
						var eTempDiv5 = (eTemp/5);
						if (eTempDiv5<=1)	// 0=hour or 1=2nd time
						{
							eStr = formatHourForDisplayString((eTempDiv5==1) ? hour2nd : hour, use24Hour, addLeadingZero);
						}
						else	// 2,3,4=sun 5,6,7=dawn/dusk
						{
							eStr = getSunDisplayString((eTempDiv5-2)%3, dateInfoShort, false, use24Hour, addLeadingZero, (eTempDiv5>=5)?8:0);
						}
					}
					else		// string
					{
						switch(eDisplay)	// type of string
						{
							case 1/*FIELD_HOUR*/:			// hour
							case 47/*FIELD_2ND_HOUR*/:
							{
								eStr = formatHourForDisplayString((eDisplay==47/*FIELD_2ND_HOUR*/) ? hour2nd : hour, updateIs24Hour, false);
								//eStr = ".1,";							// test the "." character
								break;
							}
		
							case 2/*FIELD_MINUTE*/:			// minute
							case 110/*FIELD_2ND_MINUTE*/:
						    {
								eStr = ((eDisplay==110/*FIELD_2ND_MINUTE*/) ? (updateTime2ndInMinutes%60) : minute).format("%02d");
								break;
							}

							case 62/*FIELD_SECOND_CHEAP*/:		// second
							case 63/*FIELD_SECOND_TRUE*/:		// second
						    {
								eStr = second.format("%02d");
								if (propSecondGfxIndex==index)
								{
									propSecondIndicatorOn = true;
								}
								break;
							}

							case 41/*FIELD_SUNRISE_HOUR*/:
							case 42/*FIELD_SUNRISE_MINUTE*/:
							case 43/*FIELD_SUNSET_HOUR*/:
							case 44/*FIELD_SUNSET_MINUTE*/:
							case 45/*FIELD_SUNEVENT_HOUR*/:
							case 46/*FIELD_SUNEVENT_MINUTE*/:
							case 104/*FIELD_DAWN_HOUR*/:
							case 105/*FIELD_DAWN_MINUTE*/:
							case 106/*FIELD_DUSK_HOUR*/:
							case 107/*FIELD_DUSK_MINUTE*/:
							case 108/*FIELD_DAWNDUSK_HOUR*/:
							case 109/*FIELD_DAWNDUSK_MINUTE*/:
							{
								var eTemp = eDisplay;
								var sunOffset = 0;
								if (eTemp>=104/*FIELD_DAWN_HOUR*/)
								{
									eTemp -= 104/*FIELD_DAWN_HOUR*/;
									sunOffset = 8;
								}
								else
								{
									eTemp -= 41/*FIELD_SUNRISE_HOUR*/;
								}
								
								eStr = getSunDisplayString(eTemp/2, dateInfoShort, (eTemp%2)==1, updateIs24Hour, false, sunOffset);
								break;
							}
	
							case 3/*FIELD_DAY_NAME*/:		// day name
							case 9/*FIELD_MONTH_NAME*/:		// month name
						    {
								eStr = ((eDisplay==3/*FIELD_DAY_NAME*/) ? dateInfoMedium.day_of_week : dateInfoMedium.month);
	
								//eStr = "\u0158\u015a\u00c7Z\u0179\u0104";		// test string for diacritics & bounding rectangle (use system large)
								//eStr = "A\u042d\u03b8\u05e9\u069b";			// test string for other languages (unsupported)
								//eStr = ".A.";							// test the "." character
	
								// Turkish for Tue = "Salı"
								// Turkish for Jan = "ocak"
								//eStr = "Salı";		// crash
								//eStr = "Sal";			// ok
								//eStr = "Çarşamba";	// ok 
								//eStr = "şubat";		// ok
								//var t1 = eStr.toUpper();		// ok
								//var t2 = eStr.toCharArray();	// ok
								//var t3 = t1.toCharArray();	// crash
	
								if (isDynamicResourceSystemFont(dynamicResource))
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
									if (isTurkish || useUnsupportedFieldFont(eStr))
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
								
								if (isTurkish)
								{
									makeUpperCase = false;
								}
								
								//System.println("eStr=" + eStr + " useUnsupportedFont="+useUnsupportedFont);
								
								break;
							}
	
							case 4/*FIELD_DAY_OF_WEEK*/:			// day number of week
						    {
								eStr = "" + dayNumberOfWeek(dateInfoShort);	// 1-7
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
								calculateDayWeekYearData(0, dateInfoMedium);
	
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
								calculateDayWeekYearData(1, dateInfoMedium);							
	        					eStr = ((eDisplay==14/*FIELD_WEEK_ISO_XX*/) ? ISOWeek.format("%02d") : "" + ISOYear);
	    						break;
							}
		
							case 17/*FIELD_WEEK_CALENDAR_XX*/:			// week number of year XX
							case 18/*FIELD_YEAR_CALENDAR_WEEK_XXXX*/:
							{
								calculateDayWeekYearData(2, dateInfoMedium);							
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
								fieldActiveNotificationsCount = updateNotificationCount; 
								eStr = "" + fieldActiveNotificationsCount;
								break;
							}
							
							case 36/*FIELD_BATTERYPERCENTAGE*/:
							{
								eStr = "" + updateBatteryLevel.toNumber();
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
	
							case 48/*FIELD_CALORIES*/:
							{
								eStr = "" + getNullCheckZero(activityMonitorInfo.calories);
								break;
							}
	
							case 49/*FIELD_ACTIVE_CALORIES*/:
							case 61/*FIELD_RESTING_CALORIES*/:
							{
								var val = ((eDisplay==49/*FIELD_ACTIVE_CALORIES*/) ? getActiveCalories(activityMonitorInfo.calories, timeNowInMinutesToday) : getRestCalories(timeNowInMinutesToday));
								eStr = "" + ((val<0) ? "0" : val);
								break;
							}
	
							case 111/*FIELD_TRAINING_LOAD*/:
							{
								updateSmartTrainingLoad(60, activityMonitorInfo, timeNowInMinutesToday, dateInfoMedium.year);
								eStr = "" + getMinMax(Math.round(stlTrainingLoad*100), 0, 1000).toNumber();
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
								eStr = "" + ((getNullCheckZero(activityMonitorInfo.activeMinutesWeekGoal) * dayNumberOfWeek(dateInfoShort)) / 7);
								break;
							}
	
							case 53/*FIELD_DISTANCE*/:
							{
								// convert cm to miles or km
								var d = getNullCheckZero(activityMonitorInfo.distance) / ((distanceUnits==System.UNIT_STATUTE) ? 160934.4 : 100000.0);
								eStr = d.format("%.1f");
								break;
							}
	
							case 54/*FIELD_DISTANCE_UNITS*/:
							{
								eStr = ((distanceUnits==System.UNIT_STATUTE) ? "mi" : "km");
								makeUpperCase = !isDynamicResourceSystemFont(dynamicResource);
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
								makeUpperCase = !isDynamicResourceSystemFont(dynamicResource);
								break;
							}
	
							case 57/*FIELD_ALTITUDE*/:
							{
								// convert m to feet or m
								eStr = ((elevationUnits==System.UNIT_STATUTE) ? (positionAltitude*3.2808399) : positionAltitude).format("%d");
								break;
							}
	
							case 58/*FIELD_ALTITUDE_UNITS*/:
							{
								eStr = ((elevationUnits==System.UNIT_STATUTE) ? "ft" : "m");
								makeUpperCase = !isDynamicResourceSystemFont(dynamicResource);
								break;
							}
	
							case 59/*FIELD_TEMPERATURE*/:
							{
								if (hasTemperatureHistory)
								{
									var temperatureSample = SensorHistory.getTemperatureHistory({:period => 1}).next();
									if (temperatureSample!=null && temperatureSample.data!=null)
									{ 
										eStr = (Math.round((temperatureUnits==System.UNIT_STATUTE) ? (temperatureSample.data*1.8 + 32) : temperatureSample.data)).format("%d");
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
								eStr = ((temperatureUnits==System.UNIT_STATUTE) ? "F" : "C");
								break;
							}
						}
					}
					
					if (eStr != null)
					{
						if (useUnsupportedFont)
						{
							var resourceIndex = gfxAddDynamicResources(0/*APPFONT_SYSTEM_XTINY*/ + propFieldFontUnsupported);
							gfxData[index+2/*string_font*/] &= ~0x00FF0000;
							gfxData[index+2/*string_font*/] |= ((resourceIndex & 0xFF) << 16);
							dynamicResource = getDynamicResource(resourceIndex);
						}

						if (dynamicResource!=null)
						{
							if (makeUpperCase)
							{
								eStr = eStr.toUpper();
							}
	
							var sLen = gfxCharArrayLen;
							var eLen;
							
							eLen = addStringToCharArray(eStr, gfxCharArray, sLen, 150/*MAX_GFX_CHARS*/, checkDiacritics);
							if (checkDiacritics)
							{
								gfxCharArrayLen = eLen + (eLen-sLen);
								eStr = StringUtil.charArrayToString(gfxCharArray.slice(sLen, eLen));	// string without diacritics
	
								gfxData[index+2/*string_font*/] |= 0x80000000;		// diacritics flag
							}
							else
							{
								gfxCharArrayLen = eLen;
	
								gfxData[index+2/*string_font*/] &= ~0x80000000;		// diacritics flag
							}
		
							gfxData[index+4] = sLen;	// string start
							gfxData[index+5] = eLen;	// string end
							gfxData[index+6] = dc.getTextWidthInPixels(eStr, dynamicResource);
							gfxData[indexCurField+4] += gfxData[index+6];	// total width
							updateFieldMaxAscentDescentResource(indexCurField+5, dynamicResource);		// store max ascent & descent in field
							//gfxData[indexCurField+5] = 0;	// remove existing x adjustment
						}					
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

						var dynamicResource = getDynamicResourceFromGfx(index+2/*icon_font*/);
						if (dynamicResource==null)
						{
							break;
						}

						gfxData[index+4] = c;	// char
						gfxData[index+5] = dc.getTextWidthInPixels(c.toString(), dynamicResource);
						gfxData[indexCurField+4] += gfxData[index+5];	// total width					
						updateFieldMaxAscentDescentResource(indexCurField+5, dynamicResource);		// store max ascent & descent in field
						//gfxData[indexCurField+5] = 0;	// remove existing x adjustment
						
						if (eDisplay==17/*FIELD_SHAPE_BATTERY*/ || eDisplay==18/*FIELD_SHAPE_BATTERY_SOLID*/)
						{
							prevBatteryIndex = index;
						}
				    }
				    else
				    {
						gfxData[index+4] = prevBatteryIndex;		// index of battery icon (instead of character)
				    }

					break;
				}
				
				case 5:		// movebar
				{
					if (!(fieldVisible && isVisible))
					{
						break;
					}

					gfxData[index+9] = getNullCheckZero(activityMonitorInfo.moveBarLevel);	// level
					gfxData[index+10] = 0;	// width

					var dynamicResource = getDynamicResourceFromGfx(index+2/*movebar_font*/);
					if (dynamicResource==null)
					{
						break;
					}

					// moveBarLevel 0 = not triggered
					// moveBarLevel has range 1 to 5
					// moveBarNum goes from 1 to 5
					//for (var i=0; i<5; i++)
					//{
					//	var barIsOn = (i < gfxData[index+9]);
					//	var s = (barIsOn ? "1" : "0");
					//	var w = dc.getTextWidthInPixels(s, dynamicResource);
					//
					//	gfxData[index+10] += w + ((i<4) ? -5 : 0);
					//}
					
					// since "1" and "0" chars in movebar are the same width we can do it cheaper:
					gfxData[index+10] = dc.getTextWidthInPixels("1", dynamicResource)*5 - (5*4);

					gfxData[indexCurField+4] += gfxData[index+10];	// total width
					updateFieldMaxAscentDescentResource(indexCurField+5, dynamicResource);		// store max ascent & descent in field
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
					updateFieldMaxAscentDescent(indexCurField+5, 21/*heartChartHeight*/, 0);		// store max ascent & descent in field
					//gfxData[indexCurField+5] = 0;	// remove existing x adjustment

					break;
				}
				
				case 7:		// rectangle
				{
					if (!isVisible)
					{
						break;
					}

					var direction = ((gfxData[index+1/*rect_type*/]&0xC0)>>6);	// 0=right, 1=left, 2=up, 3=down 
					var drawRange = gfxData[index + ((direction<=1) ? 6/*rect_w*/ : 7/*rect_h*/)];
					
					calcDataLimit100 = true;
					calcDirAnti = -1;
					calcSecond = second;
					gfxData[index+8/*rect_fill*/] = calculateDataFillValues((gfxData[index+1/*rect_type*/] & 0x3F), 0, drawRange, 1,
												minute, timeNowInMinutesToday, activityMonitorInfo, dateInfoShort, dateInfoMedium);
					
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

					var drawStart = gfxData[index+3];	// 0-59
					var drawEnd = gfxData[index+4];		// 0-59
					
					var gfxDataIndex1 = gfxData[index+1];
					var eDirAnti = ((gfxDataIndex1 & 0x40) != 0);	// false==clockwise

					var drawRange = ((eDirAnti ? (drawStart-drawEnd) : (drawEnd-drawStart)) + 60)%60 + 1;	// 1-60
					//var eDisplay = (gfxDataIndex1 & 0x3F);

					calcDataLimit100 = ((gfxDataIndex1 & 0x80) != 0);
					calcDirAnti = (eDirAnti ? 1 : 0);
					calcSecond = second;
					gfxData[index+8] = calculateDataFillValues((gfxDataIndex1 & 0x3F), drawStart, drawRange, (outerAlignedToSeconds(arrayResource) ? 0 : 1),
												minute, timeNowInMinutesToday, activityMonitorInfo, dateInfoShort, dateInfoMedium);

					break;
				}
				
				case 9:	// seconds
				{
					if (propSecondGfxIndex==index)
					{
						propSecondIndicatorOn = isVisible;
					}
					break;
				}
			}
			
			//index += gfxSize(id);
			if (id<0 || id>=10/*GFX_SIZE_NUM*/)
			{
				break;
			}
			index += gfxSizeArray[id]; 	// cheaper with no function call in loop
		}
	}
	
	var calcDataLimit100;
	var calcDirAnti;
	var calcSecond;
	function calculateDataFillValues(eDisplay, drawStart, drawRange, alignedAdjust, minute, timeNowInMinutesToday, activityMonitorInfo, dateInfoShort, dateInfoMedium)
	{
		// calculate fill amounts from 0 to drawRange
		var noFill = false;
		var fillStart = 0;		// first segment of outer ring to draw as filled (0 to 59)
		var fillEnd = drawRange-1;		// last segment of outer ring to draw as filled (0 to 59)

		// 0 RING_PLAIN_COLOR
		// 1 RING_STEPS
		// 2 RING_FLOORS
		// 3 RING_BATTERY
		// 4 RING_MINUTE
		// 5 RING_HOUR
		// 6 RING_2ND_HOUR
		// 7 RING_SUN_NOW
		// 8 RING_SUN_MIDNIGHT
		// 9 RING_SUN_NOON
		// 10 RING_INTENSITY
		// 11 RING_SMART_INTENSITY
		// 12 RING_HEART
		// 13 RING_ACTIVE_CALORIES
		// 14 RING_HOUR_12
		// 15 RING_HOUR_24
		// 16 RING_2ND_HOUR_12
		// 17 RING_2ND_HOUR_24
		// 18 RING_DAY_OF_WEEK
   		// 19 RING_DAY_OF_MONTH
   		// 20 RING_DAY_OF_YEAR
   		// 21 RING_MONTH_OF_YEAR
   		// 22 RING_NOTIFICATIONS
   		// 23 RING_MOVEBAR
		// 24 RING_2ND_MINUTE
		// 25 RING_DAWNDUSK_NOW
		// 26 RING_DAWNDUSK_MIDNIGHT
		// 27 RING_DAWNDUSK_NOON
		//
		// Other things that could be displayed:
		//
   		// week ISO
   		// week calendar
   		//
   		// weekly active calories compared to previous weeks
   		// smart training performance/load
   		//
   		// pressure	870-1084mb, standard at sea level is 1013, 300 on top of Everest, normal range is 1016+-34
   		// temperature -50 to +50 ?
	   		
		switch (eDisplay)
		{
			//case 0:		// solid color
			//{
			//	break;
			//}
		
			case 1/*RING_STEPS*/:		// steps
			case 2/*RING_FLOORS*/:		// floors
			case 10/*RING_INTENSITY*/:	// intensity
			case 11/*RING_SMART_INTENSITY*/:	// smart intensity
			{
				var val;
				var goal;
				if (eDisplay==2/*RING_FLOORS*/)
				{
					val = (hasFloorsClimbed ? getNullCheckZero(activityMonitorInfo.floorsClimbed) : 0);
					goal = (hasFloorsClimbed ? getNullCheckZero(activityMonitorInfo.floorsClimbedGoal) : 0);
				}
				else if (eDisplay==10/*RING_INTENSITY*/ || eDisplay==11/*RING_SMART_INTENSITY*/)
				{
					val = ((activityMonitorInfo.activeMinutesWeek!=null) ? activityMonitorInfo.activeMinutesWeek.total : 0);
					goal = getNullCheckZero(activityMonitorInfo.activeMinutesWeekGoal);

					if (eDisplay==11/*RING_SMART_INTENSITY*/)	// smart
					{
						goal = ((goal * dayNumberOfWeek(dateInfoShort)) / 7);
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
					if (drawRange<60 || calcDataLimit100)
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

	   		case 3/*RING_BATTERY*/:		// battery percentage
	   		{
				fillEnd = (updateBatteryLevel * drawRange).toNumber() / 100 - alignedAdjust;
				break;
	   		}
	   		
			case 4/*RING_MINUTE*/:		// minutes
			case 24/*RING_2ND_MINUTE*/:
			{
    			fillEnd = (((eDisplay==24/*RING_2ND_MINUTE*/) ? (updateTime2ndInMinutes%60) : minute) * drawRange)/60 - alignedAdjust;
				break;
			}
			
			case 18/*RING_DAY_OF_WEEK*/:
			{
				fillEnd = (dayNumberOfWeek(dateInfoShort) * drawRange)/7 - alignedAdjust;	// dayNumberOfWeek is 1-7
				break;
			}
			
	   		case 19/*RING_DAY_OF_MONTH*/:
			{
				fillEnd = dateInfoMedium.day - alignedAdjust;
				break;
			}

	   		case 20/*RING_DAY_OF_YEAR*/:
			{
				calculateDayWeekYearData(0, dateInfoMedium);
				fillEnd = (dayOfYear * drawRange)/365 - alignedAdjust;		// dayOfYear 1-365
				break;
			}

	   		case 21/*RING_MONTH_OF_YEAR*/:
			{
				fillEnd = (dateInfoShort.month * drawRange)/12 - alignedAdjust;
				break;
			}

	   		case 22/*RING_NOTIFICATIONS*/:
			{
				fieldActiveNotificationsCount = updateNotificationCount; 
				fillEnd = fieldActiveNotificationsCount - 1;
				break;
			}

	   		case 23/*RING_MOVEBAR*/:
			{
				// moveBarLevel 0 = not triggered
				// moveBarLevel has range 1 to 5
				fillEnd = (getNullCheckZero(activityMonitorInfo.moveBarLevel) * drawRange)/5 - 1;
				break;
			}

			case 5/*RING_HOUR*/:		// hours
			case 6/*RING_2ND_HOUR*/:		// 2nd time zone hours
			case 14/*RING_HOUR_12*/:
			case 15/*RING_HOUR_24*/:
			case 16/*RING_2ND_HOUR_12*/:
			case 17/*RING_2ND_HOUR_24*/:
			{
				var useTimeInMinutes = ((eDisplay==6/*RING_2ND_HOUR*/ || eDisplay>=16/*RING_2ND_HOUR_12*/ /*>= test also handles 24 hour */ /*RING_2ND_HOUR_24*/) ? updateTime2ndInMinutes : timeNowInMinutesToday);
				var use24Hour = ((eDisplay<=6/*RING_2ND_HOUR*/) ? updateIs24Hour : ((eDisplay%2)==1));
		        if (use24Hour)
		        {
	        		//backgroundOuterFillEnd = ((hour*60 + minute) * 120) / (24 * 60);
	        		fillEnd = (useTimeInMinutes * drawRange) / (24*60) - alignedAdjust;
		        }
		        else        	// 12 hours
		        {
	        		fillEnd = ((useTimeInMinutes%(12*60)) * drawRange) / (12*60) - alignedAdjust;
		        }
				break;
	   		}
	   		
	   		case 7/*RING_SUN_NOW*/:				// sunrise & sunset now top
	   		case 8/*RING_SUN_MIDNIGHT*/:		// sunrise & sunset midnight top
	   		case 9/*RING_SUN_NOON*/:			// sunrise & sunset noon top
	   		case 25/*RING_DAWNDUSK_NOW*/:			// dawn & dusk now top
	   		case 26/*RING_DAWNDUSK_MIDNIGHT*/:		// dawn & dusk midnight top
	   		case 27/*RING_DAWNDUSK_NOON*/:			// dawn & dusk noon top
	   		case 28/*RING_DAWNDUSK_NOW_MID*/:		// dawn & dusk now middle
	   		case 29/*RING_SUN_NOW_MID*/:			// sunrise & sunset now middle
	   		{
				calculateSun(dateInfoShort);

				var sunOffset = 0;
				if (eDisplay>=25/*RING_DAWNDUSK_NOW*/)
				{
					if (eDisplay==29/*RING_SUN_NOW_MID*/)
					{
						eDisplay = 10/*RING_SUN_NOW_MID*/;
					}
					else
					{
						sunOffset = 8;
						eDisplay -= (25/*RING_DAWNDUSK_NOW*/-7/*RING_SUN_NOW*/);
					}
				}

				var timeOffsetInMinutes = 0;	// midnight top
				if (eDisplay==7/*RING_SUN_NOW*/ || eDisplay==10/*RING_SUN_NOW_MID*/)				// now top or now middle
				{
					timeOffsetInMinutes = timeNowInMinutesToday;
				}
				
				if (eDisplay>=9/*RING_SUN_NOON*/)			// noon top or now middle
				{
					timeOffsetInMinutes += 12*60;
				}

				fillStart = getSunOuterFill(sunTimes[sunOffset], timeOffsetInMinutes, 0, drawRange);
				fillEnd = getSunOuterFill(sunTimes[sunOffset+1], timeOffsetInMinutes, -1, drawRange);

				break;
	   		}
	   		
	   		case 12/*RING_HEART*/:	// heart rate
	   		{
				calculateHeartRate(minute, calcSecond);
				if (heartDisplayLatest!=null)
				{
					fillEnd = getMinMax((heartDisplayLatest * drawRange) / heartMaxZone5, 0, drawRange) - alignedAdjust;
				}
				break;
	   		}
	   		
			case 13/*RING_ACTIVE_CALORIES*/:
			{
				var totalCalories = getNullCheckZero(activityMonitorInfo.calories);
				if (totalCalories>0)
				{
					fillEnd = (getActiveCalories(totalCalories, timeNowInMinutesToday) * drawRange) / totalCalories - alignedAdjust;
				}
				break;
			}

			case 30/*RING_TRAINING_LOAD*/:
			{
				updateSmartTrainingLoad(60, activityMonitorInfo, timeNowInMinutesToday, dateInfoMedium.year);
				//fillEnd = (getMinMax(stlTrainingLoad-0.5, 0.0, 1.0) * drawRange).toNumber() - alignedAdjust;	// convert to range 0.5 to 1.5 (50% to 150%)
				fillEnd = (stlTrainingLoad*0.5*drawRange).toNumber() - alignedAdjust;							// convert to range 0.0 to 2.0 (0% to 200%)
				break;
			}

	   		case 0/*RING_PLAIN_COLOR*/:		// plain color
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
		
		// apply fill offsets from start point for seconds drawing
		if (calcDirAnti == 1)
		{
			fillStart = (drawStart - fillStart + 60) % 60;
			fillEnd = (drawStart - fillEnd + 60) % 60;
			
			var temp = fillStart;
			fillStart = fillEnd;
			fillEnd = temp;
		}
		else if (calcDirAnti == 0)
		{
			fillStart = (drawStart + fillStart) % 60;
			fillEnd = (drawStart + fillEnd) % 60;
		}

		return (fillStart & 0xFFF) | ((fillEnd & 0xFFF) << 12) | (noFill ? 0x1000000 : 0);	// start fill, end fill and no fill flag
	}
	
	function gfxFieldHighlight(dc, index, x, y, w, h)
	{
	}
		
	function gfxElementHighlight(dc, index, x, y)
	{
	}
	
	function gfxDrawRectangle(dc, x, y, w, h, direction, start, end)
	{
		// direction: 0=right, 1=left, 2=up, 3=down

		var len = end-start;
		if (direction<=1)
		{
			dc.fillRectangle(x + ((direction==0) ? start : (w-end)), y, len, h);
		}
		else
		{
			dc.fillRectangle(x, y + ((direction==2) ? (h-end) : start), w, len);
		}
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
			var id = (gfxData[index] & 0x0F);	// cheaper with no function call in loop
			var isVisible = ((gfxData[index] & 0x10000) != 0);
			
//			if (id==0)		// header
//			{
//			}
			if (id==1)		// field
			{
    			//System.println("gfxDraw field");

				if (!isVisible)
				{
					fieldDraw = false;
				}
				else
				{
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
				}
			}
			else if (id>=2 && id<=5)
			{
				if (fieldDraw && isVisible)
				{
					var thisWidth = 0;
					
					if (id==2 || id==3)
					{
						thisWidth = gfxData[index+6];
					}
					else if (id==4)
					{
						thisWidth = gfxData[index+5];
					}
					else if (id==5)
					{
						thisWidth = gfxData[index+10];
					}
	
					if (fieldX<=dcWidth && (fieldX+thisWidth)>=0)	// check element x overlaps buffer
					{ 
						var dynamicResource = getDynamicResourceFromGfx(index+2/*string_font*/);		// 2/*icon_font*/ 2/*movebar_font*/				
	
						var dateY = fieldYStart;
						if (dynamicResource!=null)
						{
							dateY -= Graphics.getFontAscent(dynamicResource);		// subtract ascent
						}
					
						if (isEditor)
						{
							gfxElementHighlight(dc, index, fieldX, dateY);
						}
	
						if (dynamicResource!=null)
						{
							if (id==2 || id==3)		// large or string
							{
								var sLen = gfxData[index+4];
								var eLen = gfxData[index+5];
								if (eLen > sLen)
								{
									//	// font ascent & font height are all over the place with system fonts on different watches
									//	// - have to hard code some values for each font and for each watch?
									//	dc.setColor(Graphics.COLOR_RED, -1/*COLOR_TRANSPARENT*/);
									//	dc.fillRectangle(fieldX, timeY, gfxData[index+4]+gfxData[index+6], Graphics.getFontHeight(dynamicResource));
									
									//System.println("ascent=" + Graphics.getFontAscent(dynamicResource));
		
									var bgColor = -1/*COLOR_TRANSPARENT*/;
			
									// /*BIG_SECOND_CHEAP*/ or /*BIG_SECOND_TRUE*/  
									// /*FIELD_SECOND_CHEAP*/ or /*FIELD_SECOND_TRUE*/  
									if (!toBuffer || propSecondGfxIndex!=index)		// don't draw seconds to buffer
									{
										if (propSecondGfxIndex==index)
										{
											bufferX = fieldX;		// x
											bufferY = dateY;		// y
											
											if (propSecondTextMode==1)	// cheap
											{
												bgColor = propBackgroundColor;
											}
										}
				
										var s = StringUtil.charArrayToString(gfxCharArray.slice(sLen, eLen));
				
								        dc.setColor(getColor64FromGfx(gfxData[index+3/*string_color*/]), bgColor);
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
								}	
							}
							else if (id==4)		// icon
							{
								var c = gfxData[index+4];
								if (c > 0)
								{
							        dc.setColor(getColor64FromGfx(gfxData[index+3/*icon_color*/]), -1/*COLOR_TRANSPARENT*/);
					        		dc.drawText(fieldX, dateY - 1, dynamicResource, c.toString(), 2/*TEXT_JUSTIFY_LEFT*/);	// need to draw 1 pixel higher than expected ...
					        	}
							}
							else if (id==5)		// movebar
							{
								// moveBarLevel 0 = not triggered
								// moveBarLevel has range 1 to 5
								// moveBarNum goes from 1 to 5
								// since "1" and "0" chars in movebar are the same width just calculate once:
								var dateX = fieldX;
								var w = dc.getTextWidthInPixels("1", dynamicResource);
								for (var i=0; i<5; i++)
								{
									if (dateX<=dcWidth && (dateX+w)>=0)		// check element x overlaps buffer
									{ 
										var barIsOn = (i < gfxData[index+9]);
										var col = ((barIsOn || gfxData[index+8]==(-2/*COLOR_NOTSET*/+2/*COLOR_SAVE*/)) ? getColor64FromGfx(gfxData[index+3+i]) : getColor64FromGfx(gfxData[index+8]));
										
								        dc.setColor(col, -1/*COLOR_TRANSPARENT*/);
						        		dc.drawText(dateX, dateY - 1, dynamicResource, (barIsOn?"1":"0"), 2/*TEXT_JUSTIFY_LEFT*/);	// need to draw 1 pixel higher than expected ...
									}
									
									dateX += w + ((i<4) ? -5 : 0);
								}
							}
						}
						else if (id==4 && (gfxData[index+1]==33/*FIELD_SHAPE_BATTERY_FILL*/))
						{
							var prevBatteryIndex = gfxData[index+4];		// index of battery icon (instead of character)
							if (prevBatteryIndex>=0)
							{
								var dynamicResource = getDynamicResourceFromGfx(prevBatteryIndex+2/*string_font*/);		// 2/*icon_font*/ 2/*movebar_font*/				
								if (dynamicResource!=null)
								{
									// full fill
									//var y = fieldYStart - Graphics.getFontAscent(dynamicResource) + 3;		// subtract ascent
									//var x = fieldX - gfxData[prevBatteryIndex+5] + 3;
									//var w = gfxData[prevBatteryIndex+5] - 6;
									//var h = Graphics.getFontAscent(dynamicResource) - 4;
									//
									//dc.setColor(getColor64FromGfx(gfxData[index+3/*icon_color*/]), -1/*COLOR_TRANSPARENT*/);
									//gfxDrawRectangle(dc, x, y, w, h, 2/*up*/, 0, h/2);
									
									// fill with 1 pixel gap
									var iconH = Graphics.getFontAscent(dynamicResource);
									var iconW = gfxData[prevBatteryIndex+5];
									
							        dc.setColor(getColor64FromGfx(gfxData[index+3/*icon_color*/]), -1/*COLOR_TRANSPARENT*/);

									//var y = fieldYStart-iconH+4;
									//var x = fieldX-iconW+4;
									//var w = iconW-8;
									//var h = iconH-6;
									//gfxDrawRectangle(dc, x, y, w, h, 2/*up*/, 0, getMinMax(Math.round((h*updateBatteryLevel)/100.0).toNumber(), 0, h));

									var h = iconH-6;
									gfxDrawRectangle(dc, fieldX-iconW+4, fieldYStart-iconH+4, iconW-8, h, 2/*up*/, 0, getMinMax(Math.round((h*updateBatteryLevel)/100.0).toNumber(), 0, h));

									// horizontal line
									//var y = fieldYStart - Graphics.getFontAscent(dynamicResource) + 3 + 1 + (Graphics.getFontAscent(dynamicResource) - 4)/2;		// subtract ascent
									//var x = fieldX - gfxData[prevBatteryIndex+5] + 3;
									//var w = gfxData[prevBatteryIndex+5] - 6;
									//var h = 1;
									//
									//dc.setColor(getColor64FromGfx(gfxData[index+3/*icon_color*/]), -1/*COLOR_TRANSPARENT*/);
									//gfxDrawRectangle(dc, x, y, w, h, 2/*up*/, 0, h);
								}
							}
						}
					}
	
		        	fieldX += thisWidth;
		        }
			}
			else if (id==6)		// chart
			{
				if (fieldDraw && isVisible)
				{
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
		        }
			}
			else if (id==7)		// rectangle
			{
				if (isVisible)
				{
					var w = gfxData[index+6/*rect_w*/];
					var h = gfxData[index+7/*rect_h*/];
					var x = gfxData[index+4/*rect_x*/] - dcX - w/2;
					var y = displaySize - gfxData[index+5/*rect_y*/] - dcY - h/2;
	
					if (x<=dcWidth && (x+w)>=0 && y<=dcHeight && (y+h)>=0)
					{
						var fillGfxData = gfxData[index+8/*rect_fill*/];
						var fillStart = (fillGfxData&0xFFF);
						var fillEnd = ((fillGfxData>>12)&0xFFF);
						var noFill = ((fillGfxData&0x1000000)!=0);

						var colUnfilled = getColor64FromGfx(gfxData[index+3/*rect_unfilled*/]);
						var colFilled = getColor64FromGfx(gfxData[index+2/*rect_filled*/]);
						if (noFill)
						{
							colFilled = colUnfilled;
						}

						if (fillStart>fillEnd)
						{
							var temp = fillStart;
							fillStart = fillEnd+1;
							fillEnd = temp-1;
							
							temp = colFilled;
							colFilled = colUnfilled;
							colUnfilled = temp;
						}
						
						var direction = ((gfxData[index+1/*rect_type*/]&0xC0)>>6);	// 0=right, 1=left, 2=up, 3=down
						
						if (colFilled!=-2/*COLOR_NOTSET*/)
						{
					        dc.setColor(colFilled, -1/*COLOR_TRANSPARENT*/);
							gfxDrawRectangle(dc, x, y, w, h, direction, fillStart, fillEnd+1);
						}

						if (colUnfilled!=-2/*COLOR_NOTSET*/)
						{
							var l = ((direction<=1) ? w : h);
							if (fillStart>0 || fillEnd<l)
							{
						        dc.setColor(colUnfilled, -1/*COLOR_TRANSPARENT*/);
	
								if (fillStart>0)
								{
									gfxDrawRectangle(dc, x, y, w, h, direction, 0, fillStart);
								}
								
								if ((fillEnd+1)<l)
								{
									gfxDrawRectangle(dc, x, y, w, h, direction, fillEnd+1, l);
								}
							}
						}
					}
	
					if (isEditor)
					{
						gfxFieldHighlight(dc, index, x, y, w, h);
					}
				}
			}
			else if (id==8)	// ring
			{
				if (isVisible)
				{
	//if (hyperNum<0)
	//{
	//	break;
	//}
	
					var dynamicResource = getDynamicResourceFromGfx(index+2/*ring_font*/);
					var arrayResource = getDynamicResource(gfxData[index+9]);					
					if (dynamicResource!=null && arrayResource!=null)
					{
						var drawStart = gfxData[index+3];	// 0-59
						var drawEnd = gfxData[index+4];		// 0-59
		
						var fillGfxData = gfxData[index+8];
						var fillStart = (fillGfxData&0xFFF);
						var fillEnd = ((fillGfxData>>12)&0xFFF);
						var noFill = ((fillGfxData&0x1000000)!=0);
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
		
		//				//var outerSizeHalf = getOuterSizeHalf(arrayResource);
		//				var outerSizeHalf = arrayResource[61];
		//				var bufferXMin = bufferX - outerSizeHalf;
		//				var bufferXMax = bufferX + outerSizeHalf + 62/*BUFFER_SIZE*/;
		//				var bufferYMin = bufferY - outerSizeHalf;
		//				var bufferYMax = bufferY + outerSizeHalf + 62/*BUFFER_SIZE*/;
		
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
						if ((loopStart-testStart+60)%60<=testRange || (loopEnd-testStart+60)%60<=testRange)
						{
							var colFilled = getColor64FromGfx(gfxData[index+5]);
							var colValue = getColor64FromGfx(gfxData[index+6]);
							if (colValue==-2/*COLOR_NOTSET*/)
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
							var curCol = -2/*COLOR_NOTSET*/;
					
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
			
								if (indexCol != -2/*COLOR_NOTSET*/)	// don't draw the segment if no color is set
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
					    }
				    }
			    }
			}
//			else if (id==9)	// seconds
//			{
//			}

			//index += gfxSize(id);
			if (id<0 || id>=10/*GFX_SIZE_NUM*/)
			{
				break;
			}
			index += gfxSizeArray[id]; 	// cheaper with no function call in loop
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

	var hasTouchScreen = false;
	var smallerMenuFont = false;

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

		var editorSpecial = WatchUi.loadResource(Rez.JsonData.id_editorSpecial);
		if (editorSpecial!=null)
		{
			hasTouchScreen = editorSpecial[0];
			smallerMenuFont = editorSpecial[1];

			editorSpecial = null;
		}

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

	function gfxInsert(index, id)
	{
		var size = gfxSize(id);

		if (gfxNum+size > 500/*MAX_GFX_DATA*/)		// check enough space in gfxData for new item
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

//	function gfxAddLarge(index, dataType)	// 0==hour large, 1==minute large, 2==colon large 
//	{
//		index = gfxInsert(index, 2);
//		if (index>=0)
//		{
//			gfxData[index+1/*large_type*/] = dataType;		// type
//			gfxData[index+2/*large_font*/] = getLastFontLarge(index);
//			gfxData[index+3/*large_color*/] = -1/*COLOR_FOREGROUND*/+2/*COLOR_SAVE*/;	// color
//			// string 0
//			// width 0
//			// string 1
//			// width 1
//
//			reloadDynamicResources = true;
//		}
//		return index;
//	}

	// gfxType 2==large, 3==string
	function gfxAddString(index, gfxType, dataType)
	{
		index = gfxInsert(index, gfxType);
		if (index>=0)
		{
			gfxData[index+1] = dataType;		// type + useNumFont
			//gfxData[index+2/*string_font*/] = ((gfxType==2) ? getLastFontLarge(index) : getLastFontString(index));
			gfxData[index+2/*string_font*/] = ((gfxType==2) ? 
						getLastFont(index, 2, -1, 2/*large_font*/, 25/*m regular*/, 0) : 		// 0-9 (half fonts), 10-45 (s,m,l fonts), 46-49 (4 system number fonts) + resourceIndex + fontIndex
						getLastFont(index, 3, -1, 2/*string_font*/, 7/*m_regular*/, 1));		// 0-14 (s,m,l fonts), 15-19 (5 system fonts) + diacritics
			gfxData[index+3/*string_color*/] = -1/*COLOR_FOREGROUND*/+2/*COLOR_SAVE*/;	// color
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
			gfxData[index+3/*icon_color*/] = -1/*COLOR_FOREGROUND*/+2/*COLOR_SAVE*/;	// color
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
			gfxData[index+3] = -1/*COLOR_FOREGROUND*/+2/*COLOR_SAVE*/;	// color 1
			gfxData[index+4] = -1/*COLOR_FOREGROUND*/+2/*COLOR_SAVE*/;	// color 2
			gfxData[index+5] = -1/*COLOR_FOREGROUND*/+2/*COLOR_SAVE*/;	// color 3
			gfxData[index+6] = -1/*COLOR_FOREGROUND*/+2/*COLOR_SAVE*/;	// color 4
			gfxData[index+7] = -1/*COLOR_FOREGROUND*/+2/*COLOR_SAVE*/;	// color 5
			gfxData[index+8] = -2/*COLOR_NOTSET*/+2/*COLOR_SAVE*/;	// color off
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
			gfxData[index+2] = -1/*COLOR_FOREGROUND*/+2/*COLOR_SAVE*/;	// color chart
			gfxData[index+3] = -1/*COLOR_FOREGROUND*/+2/*COLOR_SAVE*/;	// color axes
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
			gfxData[index+2/*rect_filled*/] = -1/*COLOR_FOREGROUND*/+2/*COLOR_SAVE*/;	// color filled
			gfxData[index+3/*rect_unfilled*/] = -2/*COLOR_NOTSET*/+2/*COLOR_SAVE*/;	// color unfilled
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
			gfxData[index+5] = -1/*COLOR_FOREGROUND*/+2/*COLOR_SAVE*/;	// color filled
			gfxData[index+6] = -2/*COLOR_NOTSET*/+2/*COLOR_SAVE*/;	// color value
			gfxData[index+7] = -2/*COLOR_NOTSET*/+2/*COLOR_SAVE*/;	// color unfilled
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
			gfxData[index+2] = -1/*COLOR_FOREGROUND*/+2/*COLOR_SAVE*/; // color
			gfxData[index+3] = -2/*COLOR_NOTSET*/+2/*COLOR_SAVE*/; // color5
			gfxData[index+4] = -2/*COLOR_NOTSET*/+2/*COLOR_SAVE*/; // color10
			gfxData[index+5] = -2/*COLOR_NOTSET*/+2/*COLOR_SAVE*/; // color15
			gfxData[index+6] = -2/*COLOR_NOTSET*/+2/*COLOR_SAVE*/; // color0
			// xy array resource index

			reloadDynamicResources = true;
		}
		return index;
	}

//	function getLastFontLarge(index)
//	{
//		// 0-9 (half fonts), 10-45 (s,m,l fonts), 46-49 (4 system number fonts) + resourceIndex + fontIndex
//		return getLastFont(index, 2, -1, 2/*large_font*/, 25/*m regular*/, 0);
//	}

//	function getLastFontString(index)
//	{
//		// 0-14 (s,m,l fonts), 15-19 (5 system fonts) + diacritics
//		return getLastFont(index, 3, -1, 2/*string_font*/, 7/*m_regular*/, 1);
//	}
	
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
		for (var i=prevGfxField(index); i>=0; )		// start from beginning of field
		{
			i = nextGfx(i);
			if (i>=index)			// stop when get back to test element
			{
				break;
			}
			
			// keep testing all elements so we end up getting the one previous to the test index
			var id = getGfxId(i);
			if (id==id1 || id==id2)
			{
				f = (gfxData[i+gfxOffset]&0xFF);
			}
		}

//		// look for previous font in same field
//		for (var i=index; f<0; )
//		{
//			i = prevGfx(i);
//			if (i<0 || gfxIsField(i))
//			{
//				break;
//			}
//			
//			var id = getGfxId(i);
//			if (id==id1 || id==id2)
//			{
//				f = (gfxData[i+gfxOffset]&0xFF);
//			}
//		}
		
		// dont bother looking at next because its a waste of code - we always add new items at the end of the field
//		// look for next font in same field
//		for (var i=index; f<0; )
//		{
//			i = nextGfx(i);
//			if (i<0 || gfxIsField(i))
//			{
//				break;
//			}
//			
//			var id = getGfxId(i);
//			if (id==id1 || id==id2)
//			{
//				f = (gfxData[i+gfxOffset]&0xFF);
//			}
//		}
		
		if (f<0)
		{
			// search for first font in any field (that is not itself!!)
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
		var size = gfxSize(getGfxId(index));
		for (var i=index+size; i<gfxNum; i++)
		{
			gfxData[i-size] = gfxData[i];
		}
		gfxNum -= size;
	}

	function nextGfx(index)
	{
		var nextIndex = index + gfxSize(getGfxId(index));
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

			temp += gfxSize(getGfxId(temp));
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
			if (temp>=index)
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
		menuHide = !menuHide;

    	WatchUi.requestUpdate();
    	
        return true;
    }

    function onNextPage()	// tap left bottom
    {
    	if (!menuHide)
    	{
	    	var newMenuItem = menuItem.onNext();
	    	if (newMenuItem!=null)
	    	{
	    		menuItem = newMenuItem;
	    	}
		}
		menuHide = false;

    	WatchUi.requestUpdate();

        return true;
    }

    function onPreviousPage()	// tap left middle
    {
    	if (!menuHide)
    	{
	    	var newMenuItem = menuItem.onPrevious();
	    	if (newMenuItem!=null)
	    	{
	    		menuItem = newMenuItem;
	    	}
		}    
		menuHide = false;

    	WatchUi.requestUpdate();
    
        return true;
    }

    function onSelect()		// tap right top
    {
    	if (!menuHide)
    	{
			if (isColorEditing())
			{
				switchColorEditingMode();	// do this before menu handles select so that we don't change when first start editing a color
			}
	
	    	var newMenuItem = menuItem.onSelect();
	    	if (newMenuItem!=null)
	    	{
	    		menuItem = newMenuItem;
	    	}
		}
		else
		{
			// for select this needs to be in an else switch
			// - in order to handle selecting the "menu hide" menu option!
			//menuHide = false;
			
			gfxVisibilityMode = (gfxVisibilityMode+1)%3;
		}
		
    	WatchUi.requestUpdate();
    
        return true;
    }

    function onBack()	// tap right bottom
    {
    	if (!menuHide)
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
		}
		menuHide = false;
		
    	WatchUi.requestUpdate();
    
        return true;
    }

//    function onKey(keyEvent) 	// a physical button has been pressed and released. 
//    {
////System.println("onKey=" + keyEvent.getKey());
//		//keyEvent.getKey();
//		//KEY_POWER = power key
//		//KEY_LIGHT = light key
//		//KEY_ZIN = zoom in key
//		//KEY_ZOUT = zoom out key
//		//KEY_ENTER = enter key (select button)
//		//KEY_ESC = escape key
//		//KEY_FIND = find key
//		//KEY_MENU = menu key
//		//KEY_DOWN = down key
//		//KEY_DOWN_LEFT = down left key
//		//KEY_DOWN_RIGHT = down right key
//		//KEY_LEFT = left key
//		//KEY_RIGHT = right key
//		//KEY_UP = up key
//		//KEY_UP_LEFT = up left key
//		//KEY_UP_RIGHT = up right key
//
//		//keyEvent.getType();
//		//PRESS_TYPE_DOWN = key is pressed down
//		//PRESS_TYPE_UP = key is released
//		//PRESS_TYPE_ACTION = key's action is performed
//    
//    	return false;
//    }
    
//    function onKeyPressed(keyEvent) 	// a physical button has been pressed down. 
//    {
//System.println("onKeyPressed=" + keyEvent.getKey());
//    	return false;
//    }
    
//    function onKeyReleased(keyEvent) 	// a physical button has been released. 
//    {
//System.println("onKeyReleased=" + keyEvent.getKey());
//    	return false;
//    }
        
//    function onTap(clickEvent)		// a screen tap event has occurred. 
//    {
//    	//clickEvent.getCoordinates();
//    	//clickEvent.getType();
//    	//CLICK_TYPE_TAP = tap on the screen
//		//CLICK_TYPE_HOLD = press and hold on the screen
//		//CLICK_TYPE_RELEASE = release of a hold on the screen
//
//    	return false;
//    }

//    function onHold(clickEvent)		// a touch screen hold event has occurred. 
//    {
//    	//clickEvent.getCoordinates();
//    	//clickEvent.getType();
//    	//CLICK_TYPE_TAP = tap on the screen
//		//CLICK_TYPE_HOLD = press and hold on the screen
//		//CLICK_TYPE_RELEASE = release of a hold on the screen
//
//    	return false;
//    }
    
//    function onRelease(clickEvent) 		// a touch screen release event has occurred. 
//    {
//    	//clickEvent.getCoordinates();
//    	//clickEvent.getType();
//    	//CLICK_TYPE_TAP = tap on the screen
//		//CLICK_TYPE_HOLD = press and hold on the screen
//		//CLICK_TYPE_RELEASE = release of a hold on the screen
//
//    	return false;
//    }
    
//    function onSwipe(swipeEvent) 	// a touch screen swipe event has occurred. 
//    {
//    	//swipeEvent.getDirection();
// 		//SWIPE_UP = swipe in the upward direction
//		//SWIPE_RIGHT = swipe towards the right
//		//SWIPE_DOWN = swipe in the downward direction
//		//SWIPE_LEFT = swipe towards the left
//    	
//    	return false;
//    }    

	//const MAX_PROFILE_STRING_LENGTH = 510; 		// 255*2

	var lastProfileStringLength = 0;
	
	function getUsedProfileStringLength()
	{
		return lastProfileStringLength.toFloat()/510/*MAX_PROFILE_STRING_LENGTH*/; 
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

	// normal, at least 1 element visible, all elements visible
	var gfxVisibilityMode = 0;

	var menuHide = false;
	var menuY = 50;
	
	function isMenuAtTop()
	{
		return (menuY<120);
	}
	
	// off, 1 bar, all bars
	var memoryDisplayMode = 1;
	
	function handleSettingsChanged(second)
	{
    	myView.handleSettingsChanged(second);

		// when loading new gfx from settings, then should reset the menu to be at global settings	
		menuFieldGfx = 0;
		menuElementGfx = 0;
		endColorEditing();	// also end any color editing that might have been active!
		menuHide = false;
		if (menuItem==null || !(menuItem instanceof myMenuItemSaveLoadProfile))
		{
			menuItem = null;
			menuItem = new myMenuItemFieldSelect();
		}
	}
	
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

    	if (!menuHide)
		{
	    	if (isColorEditing() && (colorEditingMode>=1 && colorEditingMode<=3))
			{
	    		drawColorGrid(dc);
	    	}
	    	
	    	if (!isColorEditing() || (colorEditingMode<=1))
			{
		    	var x = (displaySize*25)/240;
		    	var y = (displaySize*menuY)/240;
		
		    	drawMenu(dc, x, y);    	// then draw any menus on top
		    	
		    	drawMemory(dc, x, y);	// draw a memory indicator
			}
		}
    }

	function gfxAddDynamicResources(fontIndex)
	{		
		if (gfxNum>0 && getGfxId(0)==0)		// header - calculate values from this here so similar to gfxOnUpdate
		{
			gfxMinMaxInPlace(0+5, -1/*COLOR_FOREGROUND*/+2/*COLOR_SAVE*/, 63+2/*COLOR_SAVE*/);	// propMenuColor
			gfxMinMaxInPlace(0+6, -2/*COLOR_NOTSET*/+2/*COLOR_SAVE*/, 63+2/*COLOR_SAVE*/);	// propMenuBorder
			gfxMinMaxInPlace(0+7, -2/*COLOR_NOTSET*/+2/*COLOR_SAVE*/, 63+2/*COLOR_SAVE*/);	// propFieldHighlight
			gfxMinMaxInPlace(0+8, -2/*COLOR_NOTSET*/+2/*COLOR_SAVE*/, 63+2/*COLOR_SAVE*/);	// propElementHighlight
		}
		
		return myView.gfxAddDynamicResources(fontIndex);
	}
	
	function editorCheckGfxVisibility(index)
	{
		if ((gfxData[index]&0x10000)==0)	// not visible
		{
			if (index==menuElementGfx || index==menuFieldGfx || (menuHide && gfxVisibilityMode==2))
			{
				gfxData[index] |= 0x10000; 	// make the element temporarily visible
			}
			else
			{
				// make sure the last element in a field is visible when selecting that field
				// (if no other element in that field is visible)
				// - we test the last one since only then have we calculated the visibility for all the other elements ...
				if (menuElementGfx==0 && !gfxIsField(index))
				{
					var nextIndex = nextGfx(index);
					if (nextIndex<0 || gfxIsField(nextIndex))
					{
						var tempIndex = prevGfxField(index);
						if (tempIndex==menuFieldGfx || (menuHide && gfxVisibilityMode==1))	// check in highlighted field
						{
							for (;;)
							{
								tempIndex=nextGfx(tempIndex);
								
								if (tempIndex<0 || (gfxData[tempIndex]&0x10000)!=0 || tempIndex>index)
								{
									break;
								}
								
								if (tempIndex==index)	// got here without finding anything else in field visible
								{
									gfxData[index] |= 0x10000; 	// make the element temporarily visible
									break;
								}
							}
						}
					}
				}
			}
		}
		
		return ((gfxData[index]&0x10000)!=0); 
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

		// make sure the menu color is visible
		var testColor = ((propMenuBorder!=-2/*COLOR_NOTSET*/) ? propMenuBorder : propBackgroundColor);  
		if (propMenuColor==testColor)
		{
 			propMenuColor = ((testColor==0) ? 0xFFFFFF : 0x000000); 
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
			
			var font = (smallerMenuFont ? Graphics.FONT_SYSTEM_XTINY : Graphics.FONT_SYSTEM_TINY);
			
			if (isMenuAtTop())
			{
				yText -= Graphics.getFontAscent(font);
			}
			else
			{
				var textSize = dc.getTextDimensions(eStr, font);
				yText -= textSize[1];
				yText += Graphics.getFontDescent(font);
			}
		
			// following only works on 3.1.0 +
			//eStr = Graphics.fitTextToArea(eStr, font, editorView.displaySize - xText - x*1.5, editorView.displaySize, true);
		
			//drawMultiText(dc, eStr, xText, yText, font);
			
			//xEnd = xText + dc.getTextWidthInPixels(eStr, font) + 5;		
			
			if (propMenuBorder!=-2/*COLOR_NOTSET*/)
			{
				dc.setColor(propMenuBorder, -1/*COLOR_TRANSPARENT*/);
				var dim = dc.getTextDimensions(eStr, font);
				dc.fillRectangle(xText-3, yText, dim[0]+6, dim[1]+2);
			}
			
			dc.setColor(propMenuColor, -1/*COLOR_TRANSPARENT*/);
			dc.drawText(xText, yText, font, eStr, 2/*TEXT_JUSTIFY_LEFT*/);
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

//    	if (menuItem.hasDirection(2))	// left
//    	{
//			drawMultiText(dc, "E", x, y-15, editorFontResource);
//		}
//
//    	if (menuItem.hasDirection(hasTouchScreen?1:0))	// up
//    	{
//			drawMultiText(dc, "C", x+13, y-20, editorFontResource);
//		}
//
//    	if (menuItem.hasDirection(hasTouchScreen?0:1))	// down
//    	{
//			drawMultiText(dc, "D", x+13, y-10, editorFontResource);
//		}
//
//    	if (menuItem.hasDirection(3))	// right
//    	{
//			//drawText(dc, "F", xEnd, y-15, editorView.editorFontResource);
//			drawMultiText(dc, "F", x+26, y-15, editorFontResource);
//		}
		
		if (propMenuBorder!=-2/*COLOR_NOTSET*/)
		{
			dc.setColor(propMenuBorder, -1/*COLOR_TRANSPARENT*/);
	    	if (menuItem.hasDirection(2))	// left
	    	{
				//dc.drawText(x, y-15, editorFontResource, "E", 2/*TEXT_JUSTIFY_LEFT*/);
				dc.fillRectangle(x+1, y-15+3, 13, 13);
			}
	
	    	if (menuItem.hasDirection(hasTouchScreen?1:0))	// up
	    	{
				//dc.drawText(x+13, y-20, editorFontResource, "C", 2/*TEXT_JUSTIFY_LEFT*/);
				dc.fillRectangle(x+13+1, y-20+3, 13, 13);
			}
	
	    	if (menuItem.hasDirection(hasTouchScreen?0:1))	// down
	    	{
				//dc.drawText(x+13, y-10, editorFontResource, "D", 2/*TEXT_JUSTIFY_LEFT*/);
				dc.fillRectangle(x+13+1, y-10+3, 13, 13);
			}
	
	    	if (menuItem.hasDirection(3))	// right
	    	{
				//dc.drawText(x+26, y-15, editorFontResource, "F", 2/*TEXT_JUSTIFY_LEFT*/);
				dc.fillRectangle(x+26+1, y-15+3, 13, 13);
			}
		}
				
		dc.setColor(propMenuColor, -1/*COLOR_TRANSPARENT*/);
    	if (menuItem.hasDirection(2))	// left
    	{
			dc.drawText(x, y-15, editorFontResource, "E", 2/*TEXT_JUSTIFY_LEFT*/);
		}

    	if (menuItem.hasDirection(hasTouchScreen?1:0))	// up
    	{
			dc.drawText(x+13, y-20, editorFontResource, "C", 2/*TEXT_JUSTIFY_LEFT*/);
		}

    	if (menuItem.hasDirection(hasTouchScreen?0:1))	// down
    	{
			dc.drawText(x+13, y-10, editorFontResource, "D", 2/*TEXT_JUSTIFY_LEFT*/);
		}

    	if (menuItem.hasDirection(3))	// right
    	{
			dc.drawText(x+26, y-15, editorFontResource, "F", 2/*TEXT_JUSTIFY_LEFT*/);
		}
    }
        
//	function drawMultiText(dc, s, x, y, font)
//	{
//		if (propMenuBorder!=-2/*COLOR_NOTSET*/)
//		{
//	        dc.setColor(propMenuBorder, -1/*COLOR_TRANSPARENT*/);
////	        for (var i=-1; i<=1; i+=2)
////	        {
////	        	for (var j=-1; j<=1; j+=2)
////	        	{
////					dc.drawText(x + i, y + j, font, s, 2/*TEXT_JUSTIFY_LEFT*/);
////	        	}
////	        }
//	        for (var i=-2; i<=2; i+=2)
//	        {
//	        	for (var j=-2; j<=2; j+=2)
//	        	{
//	        		if (i!=0 || j!=0)
//	        		{
//						dc.drawText(x + i, y + j, font, s, 2/*TEXT_JUSTIFY_LEFT*/);
//					}
//	        	}
//	        }
//		}
//		        
//        dc.setColor(propMenuColor, -1/*COLOR_TRANSPARENT*/);
//        //dc.setColor(propMenuColor, propMenuBorder);
//        //dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
//        //dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
//		//dc.drawText((editorView.displaySize*50)/240, (editorView.displaySize*50)/240, Graphics.FONT_SYSTEM_XTINY, eStr, 2/*TEXT_JUSTIFY_LEFT*/);
//		dc.drawText(x, y, font, s, 2/*TEXT_JUSTIFY_LEFT*/);
//	}
    
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

			dc.setColor(propMenuColor, -1/*COLOR_TRANSPARENT*/);
			//dc.setPenWidth(1);		  
			//dc.drawRectangle(x-1, y-1, w+2, h*5-2);
			dc.fillRectangle(x-1, y+1, 1, h*5-6);
			dc.fillRectangle(x+w, y+1, 1, h*5-6);
					
			drawMemoryBar(dc, x, y, w, h, usedProfileStringLength);
			drawMemoryBar(dc, x, y+(h-1)*1, w, h, usedGfxData);
			drawMemoryBar(dc, x, y+(h-1)*2, w, h, usedCharArray);
			drawMemoryBar(dc, x, y+(h-1)*3, w, h, usedDynamicResourceNum);
			drawMemoryBar(dc, x, y+(h-1)*4, w, h, usedResourceMemory);
		}
		else if (memoryDisplayMode==1)	// 1 bar
		{
			dc.setColor(propMenuColor, -1/*COLOR_TRANSPARENT*/);
			dc.setPenWidth(1);		  
			dc.drawRectangle(x-1, y-1, w+2, h+2);
					
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
		var w2 = ((w-2)*frac).toNumber();

		dc.setColor(propMenuColor, -1/*COLOR_TRANSPARENT*/);
		dc.fillRectangle(x+1, y+1, w2, h-2);

		if (propMenuBorder!=-2/*COLOR_NOTSET*/)
		{
			dc.setColor(propMenuBorder, -1/*COLOR_TRANSPARENT*/);
			dc.fillRectangle(x+1+w2, y+1, w-2-w2, h-2);
	
			dc.setPenWidth(1);		  
			dc.drawRectangle(x, y, w, h);
		}
	}

	function gfxFieldHighlight(dc, index, x, y, w, h)
	{
		if (!menuHide && index==menuFieldGfx)
		{
			// only highlight the field itself when selecting fields (at the top level of menu)
			if ((getGfxId(menuFieldGfx)==1 && menuElementGfx==0) ||		// field
				(getGfxId(menuFieldGfx)==7 && menuItem!=null && (menuItem instanceof myMenuItemFieldSelect)))		// rectangle
			{
				if (propFieldHighlight!=-2/*COLOR_NOTSET*/)
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
			var avoidTop = (y<(displaySize*80)/240);
			var avoidBottom = ((y+h)>(displaySize*160)/240);
			if (isMenuAtTop())
			{
				if (avoidTop && !avoidBottom)
				{
					menuY = 200;	// move to bottom
				}
			}
			else
			{
				if (avoidBottom & !avoidTop)
				{
					menuY = 50;		// move to top
				}
			}
		}
	}

	function getResourceFontHeightFromGfx(gfxIndex)
	{
		var dynamicResource = getDynamicResourceFromGfx(gfxIndex);
		return ((dynamicResource!=null) ? Graphics.getFontHeight(dynamicResource) : 1);
	}
		
	function gfxElementHighlight(dc, index, x, y)
	{
		if (!menuHide && index==menuElementGfx && propElementHighlight!=-2/*COLOR_NOTSET*/)
		{
			// calculation of width & height is just done by the editor to save code on the watchface
			var w = 1;
			var h = 1;
			var id = getGfxId(index);
			if (id>=2 && id<=5)
			{
				if (id==2 || id==3)		// large or string
				{
					w = gfxData[index+6];
					//h = getResourceFontHeightFromGfx(index+2/*string_font*/);
				}
				else if (id==4)		// icon
				{
					w = gfxData[index+5];
					//h = getResourceFontHeightFromGfx(index+2/*icon_font*/);
				}
				else if (id==5)		// movebar
				{
					w = gfxData[index+10];
					//h = getResourceFontHeightFromGfx(index+2/*movebar_font*/);
				}
				
				// one call since they are all the same offset
				h = getResourceFontHeightFromGfx(index+2/*string_font*/);	//2/*large_font*/ 2/*icon_font*/ 2/*movebar_font*/
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
		colorEditingMode = (colorEditingMode+1)%5;
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
	
	        if (highlightGrid>=0)
	        {
	    		dc.setColor(Graphics.COLOR_BLACK, -1/*COLOR_TRANSPARENT*/);
				dc.setPenWidth(3);
				dc.drawCircle(displayHalf + hx, displayHalf - hy, cScaleHighlight+1);
	        }
		}
	}

	function geColorName()
	{
		var colorNum = ((getColorGfxIndex>=0) ? gfxData[getColorGfxIndex] : 0);

		var rezArr = [Rez.JsonData.id_colorStrings, Rez.JsonData.id_colorStrings2, Rez.JsonData.id_colorStrings3];
		return safeStringFromJsonDataMulti(rezArr, colorNum);
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
	function safeStringFromJsonDataMulti(rezArr, index)
	{
		if (index>=0)
		{
			for (var i=0; i<rezArr.size(); i++)
			{
				var tempArray = WatchUi.loadResource(rezArr[i]);
				if (tempArray!=null && index<tempArray.size())
				{
					return tempArray[index];
				}
				index -= tempArray.size();
				tempArray = null;
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
		return safeStringFromJsonData(Rez.JsonData.id_largeTypeStrings, 0, eDisplay);
	}

	function getStringTypeName(eDisplay)
	{
		var rezArr = [Rez.JsonData.id_stringTypeStrings, Rez.JsonData.id_stringTypeStrings2, Rez.JsonData.id_stringTypeStrings3, Rez.JsonData.id_stringTypeStrings4, Rez.JsonData.id_stringTypeStrings5];
		return safeStringFromJsonDataMulti(rezArr, (eDisplay&0x7F)-1);
	}

	function getVisibilityString(gfxIndex)
	{
		var rezArr = [Rez.JsonData.id_visibilityStrings, Rez.JsonData.id_visibilityStrings2];
		return safeStringFromJsonDataMulti(rezArr, (gfxData[gfxIndex]>>4)&0x3F);
	}
	
	function fieldVisibilityString()
	{
		return getVisibilityString(menuFieldGfx);
	}

//	function fieldGetVisibility()
//	{
//		return ((gfxData[menuFieldGfx] >> 4) & 0x3F);
//	}

	function fieldVisibilityEditing(val)
	{
		val = (((gfxData[menuFieldGfx]>>4)&0x3F)+val+34/*STATUS_NUM*/)%34/*STATUS_NUM*/;
		gfxData[menuFieldGfx] &= ~(0x3F << 4);
		gfxData[menuFieldGfx] |= ((val & 0x3F) << 4);
	}

//	function fieldPositionGetX()
//	{
//		return gfxData[menuFieldGfx+1];
//	}

//	function fieldPositionGetY()
//	{
//		return gfxData[menuFieldGfx+2];
//	}

	function gfxSubtractVal(indexValue, val, min, max)
	{
		return getMinMax(indexValue+(hasTouchScreen?val:-val), min, max);
	}

	function gfxSubtractValInPlace(index, val, min, max)
	{
		gfxData[index] = gfxSubtractVal(gfxData[index], val, min, max);
	}

	function gfxSubtractValModulo(indexValue, val, min, max)
	{
		var numPlusOne = max-min+1;
		return (indexValue+(hasTouchScreen?val:-val)+numPlusOne-min)%numPlusOne + min;
	}

	function gfxSubtractValModuloInPlace(index, val, min, max)
	{
		gfxData[index] = gfxSubtractValModulo(gfxData[index], val, min, max);
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

//	function fieldGetAlignment()
//	{
//		return gfxData[menuFieldGfx+3];
//	}

//	function fieldAlignmentEditing(val)
//	{
//		gfxData[menuFieldGfx+3] = (gfxData[menuFieldGfx+3]+val+3)%3;
//	}

// save 40 bytes moving this function inline
//	function fieldPositionXEditing(val)
//	{
//		//gfxData[menuFieldGfx+1] = getMinMax(gfxData[menuFieldGfx+1]-val, 0, displaySize);
//		gfxSubtractValInPlace(menuFieldGfx+1, val, 0, displaySize);
//	}

//	function fieldPositionYEditing(val)
//	{
//		//gfxData[menuFieldGfx+2] = getMinMax(gfxData[menuFieldGfx+2]-val, 0, displaySize);
//		gfxSubtractValInPlace(menuFieldGfx+2, val, 0, displaySize);
//	}

	function menuFieldEditGetString(fState)
	{
		if (fState==12/*f_xEdit*/)
    	{
    		//return "x=" + fieldPositionGetX();
    		return "x=" + gfxData[menuFieldGfx+1];
    	}
		else if (fState==13/*f_yEdit*/)
    	{
    		//return "y=" + fieldPositionGetY();
    		return "y=" + gfxData[menuFieldGfx+2];
    	}
    	else if (fState==14/*f_alignEdit*/)
    	{
    		//return safeStringFromJsonData(Rez.JsonData.id_fieldEditStrings, 1, fieldGetAlignment());
    		return safeStringFromJsonData(Rez.JsonData.id_fieldEditStrings, 1, gfxData[menuFieldGfx+3]);
    	}
    	else if (fState==15/*f_visEdit*/)
    	{
    		return fieldVisibilityString();
    	}
    	else if (fState<=11/*f_tap*/)
    	{
    		return safeStringFromJsonData(Rez.JsonData.id_fieldEditStrings, 0, fState);
    	}
    	else
    	{
    		return "editing...";	// for x & y position
    	}
	}

	function menuFieldEditOnEditing(fState, val)
	{
		if (fState==12/*f_xEdit*/)
    	{
    		//fieldPositionXEditing(val);
			gfxSubtractValInPlace(menuFieldGfx+1, val, 0, displaySize);
    	}
		else if (fState==13/*f_yEdit*/)
    	{
    		//fieldPositionYEditing(val);
			gfxSubtractValInPlace(menuFieldGfx+2, val, 0, displaySize);
    	}
		else if (fState==14/*f_alignEdit*/)
    	{
    		//fieldAlignmentEditing(val);
			gfxData[menuFieldGfx+3] = (gfxData[menuFieldGfx+3]+val+3)%3;
    	}
		else if (fState==15/*f_visEdit*/)
    	{
    		fieldVisibilityEditing(val);
    	}
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
			gfxResetToHeader();	
		}
		
		reloadDynamicResources = true;
	}

	function menuQuickAddOnSelect(fState)
	{
    	if (fState>=0)
    	{
			var index = (fState==5 || fState==6) ? gfxAddRectangle(gfxNum) : gfxAddField(gfxNum);
	    	if (index>=0)
	    	{
	    		menuFieldGfx = index;

				if (fState==0)	// time + colon
				{
					gfxAddString(gfxNum, 2, 0/*BIG_HOUR*/);
					gfxAddString(gfxNum, 2, 2/*BIG_COLON*/);
					gfxAddString(gfxNum, 2, 1/*BIG_MINUTE*/);
				}
				else if (fState==1)	// steps text
				{
					gfxAddString(gfxNum, 3, 31/*FIELD_STEPSCOUNT*/);
					gfxAddIcon(gfxNum, 21/*FIELD_SHAPE_FOOTSTEPS*/);
				}
				else if (fState==2)	// heart rate
				{
					gfxAddString(gfxNum, 3, 40/*FIELD_HEART_LATEST*/);
					gfxAddIcon(gfxNum, 27/*FIELD_SHAPE_HEART*/);
				}
				else if (fState==3)	// battery (when low)
				{
					var elementIndex = gfxAddString(gfxNum, 3, 36/*FIELD_BATTERYPERCENTAGE*/);
					gfxData[elementIndex] |= (16/*STATUS_BATTERY_LOW*/<<4);
					elementIndex = gfxAddIcon(gfxNum, 17/*FIELD_SHAPE_BATTERY*/);
					gfxData[elementIndex] |= (16/*STATUS_BATTERY_LOW*/<<4);
				}
				else if (fState==4)	// alarm (when set)
				{
					var elementIndex = gfxAddIcon(gfxNum, 12/*FIELD_SHAPE_ALARM*/);
					gfxData[elementIndex] |= (5/*STATUS_ALARM_ON*/<<4);
				}
				else if (fState==5)	// horizontal line
				{
					gfxData[index+6/*rect_w*/] = 200;	// width
					gfxData[index+7/*rect_h*/] = 1;		// height
				}
				else if (fState==6)	// vertical line
				{
					gfxData[index+6/*rect_w*/] = 1;		// width
					gfxData[index+7/*rect_h*/] = 200;	// height
				}
			}

   			fState = -1;
    	}
    	else
    	{
   			fState = 0;
    	}
    	
    	return fState;
    }
    	
//    function headerBackgroundColorEditing(val)
//	{
//		gfxSubtractValModuloInPlace(menuFieldGfx+3, val, 2/*COLOR_SAVE*/, 65);	// 2 to 65
//		reloadDynamicResources = true;
//	}
	
//	function headerForegroundColorEditing(val)
//	{
//		gfxSubtractValModuloInPlace(menuFieldGfx+4, val, 2/*COLOR_SAVE*/, 65);	// 2 to 65
//		reloadDynamicResources = true;
//	}
	
//	function headerMenuColorEditing(val)
//	{
//		gfxSubtractValModuloInPlace(menuFieldGfx+5, val, 1/*COLOR_ONE*/, 65);	// 1 to 65
//	}
	
//	function headerMenuBorderColorEditing(val)
//	{
//		gfxSubtractValModuloInPlace(menuFieldGfx+6, val, 0, 65);	// 0 to 65
//	}
	
//	function headerFieldHighlightColorEditing(val)
//	{
//		gfxSubtractValModuloInPlace(menuFieldGfx+7, val, 0, 65);	// 0 to 65
//	}
	
//	function headerElementHighlightColorEditing(val)
//	{
//		gfxSubtractValModuloInPlace(menuFieldGfx+8, val, 0, 65);	// 0 to 65
//	}
	
//	function headerDawnDuskModeEditing(val)
//	{
//		var newMode = (propDawnDuskMode-1-val+3)%3;		// 0, 1, 2
//		gfxData[0+9] &= ~0x06;		
//		gfxData[0+9] |= (newMode<<1);		
//		sunCalculatedDay = -1;
//		reloadDynamicResources = true;
//	}
	
	function headerBatteryEditing(n, val)
	{
		var cur = gfxData[menuFieldGfx+10+n];
		if (hasTouchScreen)
		{
			val = -val;
		}
		if ((val<0 && cur>=10 && cur<=85) || (val>0 && cur>=15 && cur<=90))
		{
			val = val*5;
		} 
		gfxData[menuFieldGfx+10+n] = getMinMax(cur-val, 0, 100);	// 0 to 100
		reloadDynamicResources = true;
	}
	
//	function headerBatteryAtMax(n)
//	{
//		return (gfxData[menuFieldGfx+10+n]>=100);	// 0 to 100
//	}
	
//	function headerBatteryAtMin(n)
//	{
//		return (gfxData[menuFieldGfx+10+n]<=0);	// 0 to 100
//	}
	
	function header2ndTimeZoneGetHour()
	{
		return ((gfxData[menuFieldGfx+12]&0x03F)-24);		// 0x3F (0 to 48, 24==0), 0x1C0 (0 to 6, 0==0, 1==15, 2==30, 3==45, 4==0, 5==-45, 6=-30, 7=-15 ((x+4)%8)-4)
	}
	
	function header2ndTimeZoneGetMinute()
	{
		return (((((gfxData[menuFieldGfx+12]&0x1C0)>>6)+4)%8)-4)*15;		// 0x3F (0 to 48, 24==0), 0x1C0 (0 to 6, 0==0, 1==15, 2==30, 3==45, 4==0, 5==-45, 6=-30, 7=-15 ((x+4)%8)-4)
	}
	
//	function header2ndTimeZoneEditingHour(val)
//	{
//		var newHour = gfxSubtractVal(header2ndTimeZoneGetHour(), val, -24, 24);
//		gfxData[menuFieldGfx+12] &= ~0x03F;
//		gfxData[menuFieldGfx+12] |= ((newHour+24)&0x03F);
//		reloadDynamicResources = true;
//	}
	
//	function header2ndTimeZoneEditingMinute(val)
//	{
//		var newMinute = gfxSubtractVal(header2ndTimeZoneGetMinute()/15, val, -3, 3);
//		newMinute = (newMinute+8)%8;
//		gfxData[menuFieldGfx+12] &= ~0x1C0;
//		gfxData[menuFieldGfx+12] |= ((newMinute<<6)&0x1C0);
//		reloadDynamicResources = true;
//	}
	
//	function header2ndTimeHourAtMax()
//	{
//		return (header2ndTimeZoneGetHour()>=24);	// 0x3F (0 to 48, 24==0), 0x1C0 (0 to 6, 0==0, 1==15, 2==30, 3==45, 4==0, 5==-45, 6=-30, 7=-15 ((x+4)%8)-4)
//	}
	
//	function header2ndTimeHourAtMin()
//	{
//		return (header2ndTimeZoneGetHour()<=-24);	// 0x3F (0 to 48, 24==0), 0x1C0 (0 to 6, 0==0, 1==15, 2==30, 3==45, 4==0, 5==-45, 6=-30, 7=-15 ((x+4)%8)-4)
//	}
	
//	function header2ndTimeMinuteAtMax()
//	{
//		return (header2ndTimeZoneGetMinute()>=45);	// 0x3F (0 to 48, 24==0), 0x1C0 (0 to 6, 0==0, 1==15, 2==30, 3==45, 4==0, 5==-45, 6=-30, 7=-15 ((x+4)%8)-4)
//	}
	
//	function header2ndTimeMinuteAtMin()
//	{
//		return (header2ndTimeZoneGetMinute()<=-45);	// 0x3F (0 to 48, 24==0), 0x1C0 (0 to 6, 0==0, 1==15, 2==30, 3==45, 4==0, 5==-45, 6=-30, 7=-15 ((x+4)%8)-4)
//	}
	
//	function headerMoveBarAlertEditing(val)
//	{
//		gfxSubtractValInPlace(menuFieldGfx+13, val, 1, 5);		// 1 to 5
//		reloadDynamicResources = true;
//	}
	
//	function headerMoveBarAlertAtMax()
//	{
//		return (gfxData[menuFieldGfx+13]>=5);	// 1 to 5
//	}
	
//	function headerMoveBarAlertAtMin()
//	{
//		return (gfxData[menuFieldGfx+13]<=1);	// 1 to 5
//	}
	
//	function headerFontSystemCaseEditing(val)
//	{
//		gfxSubtractValModuloInPlace(menuFieldGfx+14, val, 0, 2);		// 0 to 2
//		reloadDynamicResources = true;
//	}
	
//	function headerFontUnsupportedEditing(val)
//	{
//		gfxSubtractValModuloInPlace(menuFieldGfx+15, val, 0, 4);		// 0 to 4
//		reloadDynamicResources = true;
//	}
	
    function menuHeaderGetString(fState)
    {
    	if (fState==106/*f_batteryHighEdit*/)
    	{
    		return "" + propBatteryHighPercentage;
    	}
    	else if (fState==107/*f_batteryLowEdit*/)
    	{
    		return "" + propBatteryLowPercentage;
    	}
    	else if (fState==108/*f_2ndTimeHourEdit*/)
    	{
    		return "" + header2ndTimeZoneGetHour();
    	}
    	else if (fState==109/*f_2ndTimeMinuteEdit*/)
    	{
    		return "" + header2ndTimeZoneGetMinute();
    	}
    	else if (fState==110/*f_moveBarAlertEdit*/)
    	{
    		return "" + propMoveBarAlertTriggerLevel;
    	}
    	else if (fState==111/*f_dawnDuskModeEdit*/)
    	{
    		return safeStringFromJsonData(Rez.JsonData.id_headerStrings2, 3, propDawnDuskMode-1);
    	}
    	else if (fState==112/*f_fontSystemCaseEdit*/)
    	{
    		return safeStringFromJsonData(Rez.JsonData.id_headerStrings2, 0, propFieldFontSystemCase);
    	}
    	else if (fState==113/*f_fontUnsupportedEdit*/)
    	{
    		return safeStringFromJsonData(Rez.JsonData.id_headerStrings2, 1, propFieldFontUnsupported);
    	}
    	else if (fState==114/*f_memoryDisplayEdit*/)
    	{
    		return safeStringFromJsonData(Rez.JsonData.id_headerStrings2, 2, memoryDisplayMode);
    	}
    	else if (fState<100/*f_backgroundEdit*/)
    	{
    		return safeStringFromJsonData(Rez.JsonData.id_headerStrings, -1, fState);
    	}
    	//else
    	//{
    	//	return "editing...";
    	//}

   		return null;
    }

	function menuHeaderHasDirection(d, fState)
	{
    	if (d==3)	// right
    	{
    	 	if (fState>=100/*f_backgroundEdit*/)
    	 	{
    			return false;
    		}
    	}
    	else if (d==(hasTouchScreen?1:0))	// up
    	{
	    	if (fState==106/*f_batteryHighEdit*/)
	    	{
			    //return !headerBatteryAtMax(0);
			    return (gfxData[menuFieldGfx+10]<100);
	    	}
	    	else if (fState==107/*f_batteryLowEdit*/)
	    	{
			    //return !headerBatteryAtMax(1);
			    return (gfxData[menuFieldGfx+10+1]<100);
	    	}
	    	else if (fState==108/*f_2ndTimeHourEdit*/)
	    	{
			    //return !header2ndTimeHourAtMax();
				return (header2ndTimeZoneGetHour()<24);	// 0x3F (0 to 48, 24==0), 0x1C0 (0 to 6, 0==0, 1==15, 2==30, 3==45, 4==0, 5==-45, 6=-30, 7=-15 ((x+4)%8)-4)
	    	}
	    	else if (fState==109/*f_2ndTimeMinuteEdit*/)
	    	{
			    //return !header2ndTimeMinuteAtMax();
				return (header2ndTimeZoneGetMinute()<45);	// 0x3F (0 to 48, 24==0), 0x1C0 (0 to 6, 0==0, 1==15, 2==30, 3==45, 4==0, 5==-45, 6=-30, 7=-15 ((x+4)%8)-4)
	    	}
	    	else if (fState==110/*f_moveBarAlertEdit*/)
	    	{
			    //return !headerMoveBarAlertAtMax();
				return (gfxData[menuFieldGfx+13]<5);	// 1 to 5
	    	}
    	}
    	else if (d==(hasTouchScreen?0:1))	// down
    	{
	    	if (fState==106/*f_batteryHighEdit*/)
	    	{
			    //return !headerBatteryAtMin(0);
				return (gfxData[menuFieldGfx+10]>0);	// 0 to 100
	    	}
	    	else if (fState==107/*f_batteryLowEdit*/)
	    	{
			    //return !headerBatteryAtMin(1);
				return (gfxData[menuFieldGfx+10+1]>0);	// 0 to 100
	    	}
	    	else if (fState==108/*f_2ndTimeHourEdit*/)
	    	{
			    //return !header2ndTimeHourAtMin();
				return (header2ndTimeZoneGetHour()>-24);	// 0x3F (0 to 48, 24==0), 0x1C0 (0 to 6, 0==0, 1==15, 2==30, 3==45, 4==0, 5==-45, 6=-30, 7=-15 ((x+4)%8)-4)
	    	}
	    	else if (fState==109/*f_2ndTimeMinuteEdit*/)
	    	{
			    //return !header2ndTimeMinuteAtMin();
				return (header2ndTimeZoneGetMinute()>-45);	// 0x3F (0 to 48, 24==0), 0x1C0 (0 to 6, 0==0, 1==15, 2==30, 3==45, 4==0, 5==-45, 6=-30, 7=-15 ((x+4)%8)-4)
	    	}
	    	else if (fState==110/*f_moveBarAlertEdit*/)
	    	{
			    //return !headerMoveBarAlertAtMin();
				return (gfxData[menuFieldGfx+13]>1);	// 1 to 5
	    	}
    	}

    	return true;
	}

	function menuHeaderOnEditing(val, fState)
	{
    	if (fState==100/*f_backgroundEdit*/)
    	{
    		//headerBackgroundColorEditing(val);
			gfxSubtractValModuloInPlace(menuFieldGfx+3, val, 2/*COLOR_SAVE*/, 65);	// 2 to 65
			reloadDynamicResources = true;
    	}
    	else if (fState==101/*f_foregroundEdit*/)
    	{
    		//headerForegroundColorEditing(val);
			gfxSubtractValModuloInPlace(menuFieldGfx+4, val, 2/*COLOR_SAVE*/, 65);	// 2 to 65
			reloadDynamicResources = true;
    	}
    	else if (fState==102/*f_menuColorEdit*/)
    	{
    		//headerMenuColorEditing(val);
			gfxSubtractValModuloInPlace(menuFieldGfx+5, val, 1/*COLOR_ONE*/, 65);	// 1 to 65
    	}
    	else if (fState==103/*f_menuBorderEdit*/)
    	{
    		//headerMenuBorderColorEditing(val);
			gfxSubtractValModuloInPlace(menuFieldGfx+6, val, 0, 65);	// 0 to 65
    	}
    	else if (fState==104/*f_fieldHighlightEdit*/)
    	{
    		//headerFieldHighlightColorEditing(val);
			gfxSubtractValModuloInPlace(menuFieldGfx+7, val, 0, 65);	// 0 to 65
    	}
    	else if (fState==105/*f_ElementHighlightEdit*/)
    	{
    		//headerElementHighlightColorEditing(val);
			gfxSubtractValModuloInPlace(menuFieldGfx+8, val, 0, 65);	// 0 to 65
    	}
    	else if (fState==106/*f_batteryHighEdit*/)
    	{
    		headerBatteryEditing(0, val);
    	}
    	else if (fState==107/*f_batteryLowEdit*/)
    	{
    		headerBatteryEditing(1, val);
    	}
    	else if (fState==108/*f_2ndTimeHourEdit*/)
    	{
    		//header2ndTimeZoneEditingHour(val);
			var newHour = gfxSubtractVal(header2ndTimeZoneGetHour(), val, -24, 24);
			gfxData[menuFieldGfx+12] &= ~0x03F;
			gfxData[menuFieldGfx+12] |= ((newHour+24)&0x03F);
			reloadDynamicResources = true;
    	}
    	else if (fState==109/*f_2ndTimeMinuteEdit*/)
    	{
    		//header2ndTimeZoneEditingMinute(val);
			var newMinute = gfxSubtractVal(header2ndTimeZoneGetMinute()/15, val, -3, 3);
			newMinute = (newMinute+8)%8;
			gfxData[menuFieldGfx+12] &= ~0x1C0;
			gfxData[menuFieldGfx+12] |= ((newMinute<<6)&0x1C0);
			reloadDynamicResources = true;
    	}
    	else if (fState==110/*f_moveBarAlertEdit*/)
    	{
    		//headerMoveBarAlertEditing(val);
			gfxSubtractValInPlace(menuFieldGfx+13, val, 1, 5);		// 1 to 5
			reloadDynamicResources = true;
    	}
    	else if (fState==111/*f_dawnDuskModeEdit*/)
    	{
    		//headerDawnDuskModeEditing(val);
			var newMode = (propDawnDuskMode-1-val+3)%3;		// 0, 1, 2
			gfxData[0+9] &= ~0x06;		
			gfxData[0+9] |= (newMode<<1);		
			sunCalculatedDay = -1;
			reloadDynamicResources = true;
    	}
    	else if (fState==112/*f_fontSystemCaseEdit*/)
    	{
    		//headerFontSystemCaseEditing(val);
			gfxSubtractValModuloInPlace(menuFieldGfx+14, val, 0, 2);		// 0 to 2
			reloadDynamicResources = true;
    	}
    	else if (fState==113/*f_fontUnsupportedEdit*/)
    	{
    		//headerFontUnsupportedEditing(val);
			gfxSubtractValModuloInPlace(menuFieldGfx+15, val, 0, 4);		// 0 to 4
			reloadDynamicResources = true;
    	}
    	else if (fState==114/*f_memoryDisplayEdit*/)
    	{
    		memoryDisplayMode = (memoryDisplayMode + val + 3)%3;
    	}
   	}
	
//	function elementVisibilityString()
//	{
//		return getVisibilityString(menuElementGfx);
//	}

//	function elementGetVisibility()
//	{
//		return ((gfxData[menuElementGfx] >> 4) & 0x3F);
//	}

	function elementVisibilityEditing(val)
	{
		val = (((gfxData[menuElementGfx]>>4)&0x3F)+val+34/*STATUS_NUM*/)%34/*STATUS_NUM*/;

		gfxData[menuElementGfx] &= ~(0x3F << 4);
		gfxData[menuElementGfx] |= ((val & 0x3F) << 4);
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

    function arrayTypeEditingValue(val, idArrayValue, rezId, rezArrayIndex)
    {
    	var newType = idArrayValue;
    
		var tempArray = WatchUi.loadResource(rezId);
    	if (tempArray!=null)
    	{
	    	tempArray = tempArray[rezArrayIndex];
		    	
	    	var index = tempArray.indexOf(idArrayValue);
	    	if (index>=0)
	    	{
	    		index = (index+val+tempArray.size())%tempArray.size();
				newType = tempArray[index];
	    	}
	    	else if (tempArray.size()>0)
	    	{
				newType = tempArray[0];
	    	}
		}
		
		return newType;
    }

// same as string now    
//	function largeGetType()
//	{
//		return gfxData[menuElementGfx+1];
//	}
		
//	function largeTypeEditing(val)
//	{
//		gfxData[menuElementGfx+1] = (largeGetType()+val+3)%3;
//		reloadDynamicResources = true;
//	}
		
    function largeTypeEditingValue(val, idArrayValue)
    {
    	return arrayTypeEditingValue(val, idArrayValue, Rez.JsonData.id_largeTypeStrings, 1);
    }
    
    function largeTypeEditing(val)
    {
		gfxData[menuElementGfx+1] = largeTypeEditingValue(val, stringGetType());
		reloadDynamicResources = true;
    }
  
// same as string now  
//	function largeColorEditing(val)
//	{
//		gfxSubtractValModuloInPlace(menuElementGfx+3/*large_color*/, val, 1/*COLOR_ONE*/, 65);	// 1 to 65
//	}

// same as string now
//	function largeGetFont()
//	{
//		return (gfxData[menuElementGfx+2/*large_font*/]&0xFF);
//	}
		
	function largeFontEditing(val)
	{	
		gfxData[menuElementGfx+2/*large_font*/] = gfxSubtractValModulo(stringGetFont(), val, 0, 49);	// 0-9 (half fonts), 10-45 (s,m,l fonts), 46-49 (4 system number fonts)
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
		
    function stringTypeEditing(val, idArrayValue, idArray)
    {
    	return arrayTypeEditingValue(val, idArrayValue, Rez.JsonData.id_addStringArrays, idArray);
    }
    
	function stringColorEditing(val)
	{
		gfxSubtractValModuloInPlace(menuElementGfx+3/*string_color*/, val, 1/*COLOR_ONE*/, 65);	// 1 to 65
	}

	function stringGetFont()
	{
		return (gfxData[menuElementGfx+2/*string_font*/]&0xFF);
	}
		
	function stringFontEditing(val)
	{
		gfxData[menuElementGfx+2/*string_font*/] = gfxSubtractValModulo(stringGetFont(), val, 0, 19);	// 0-14 (s,m,l fonts), 15-19 (5 system fonts)
		reloadDynamicResources = true;

		lastFontArray[1] = gfxData[menuElementGfx+2/*string_font*/];
	}

	function iconGetTypeName()
	{
		var rezArr = [Rez.JsonData.id_iconTypeStrings, Rez.JsonData.id_iconTypeStrings2];
		return safeStringFromJsonDataMulti(rezArr, gfxData[menuElementGfx+1]);
	}

	function iconTypeEditing(val)
	{
		//gfxData[menuElementGfx+1] = (gfxData[menuElementGfx+1]+val+32/*FIELD_SHAPE_MOUNTAIN*/+1)%(32/*FIELD_SHAPE_MOUNTAIN*/+1);
    	gfxData[menuElementGfx+1] = arrayTypeEditingValue(val, gfxData[menuElementGfx+1], Rez.JsonData.id_iconArray, 0);
		reloadDynamicResources = true;		// for battery fill bodge icons
	}

	function iconColorEditing(val)
	{
		gfxSubtractValModuloInPlace(menuElementGfx+3/*icon_color*/, val, 1/*COLOR_ONE*/, 65);	// 1 to 65
	}

	function iconGetFont()
	{
		return (gfxData[menuElementGfx+2/*icon_font*/]&0xFF);
	}

	function iconFontEditing(val)
	{
		gfxData[menuElementGfx+2/*icon_font*/] = gfxSubtractValModulo(iconGetFont(), val, 0, 1);
		reloadDynamicResources = true;

		lastFontArray[2] = gfxData[menuElementGfx+2/*icon_font*/];
	}

	function moveBarGetFont()
	{
		return (gfxData[menuElementGfx+2/*movebar_font*/]&0xFF);
	}

	function moveBarFontEditing(val)
	{
		gfxData[menuElementGfx+2/*movebar_font*/] = gfxSubtractValModulo(moveBarGetFont(), val, 0, 1);
		reloadDynamicResources = true;

		lastFontArray[2] = gfxData[menuElementGfx+2/*movebar_font*/];
	}

	function moveBarColorEditing(n, val)
	{
		gfxSubtractValModuloInPlace(menuElementGfx+3+n, val, 1/*COLOR_ONE*/, 65);	// 1 to 65
	}

	function moveBarOffColorEditing(val)
	{
		gfxSubtractValModuloInPlace(menuElementGfx+8, val, 0, 65);		// allow for COLOR_NOTSET (-2) so 0 to 65
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
		gfxSubtractValModuloInPlace(menuElementGfx+2+n, val, 1/*COLOR_ONE*/, 65);	// 1 to 65
	}

	function rectangleGetType()
	{
		return (gfxData[menuFieldGfx+1]&0x3F);
	}

//	function rectangleTypeEditing(val)
//	{
//		var eDisplay = ((gfxData[menuFieldGfx+1]&0x3F) + val + 1)%1;
//		gfxData[menuFieldGfx+1] &= ~0x3F; 
//		gfxData[menuFieldGfx+1] |= (eDisplay & 0x3F); 
//	}
	
	function rectangleGetDirection()
	{
		return ((gfxData[menuFieldGfx+1]&0xC0)>>6); 
	}
	
//	function rectangleDirectionEditing(val)
//	{
//		var temp = gfxSubtractValModulo(rectangleGetDirection(), val, 0, 3);
//		gfxData[menuFieldGfx+1] &= ~0xC0; 
//		gfxData[menuFieldGfx+1] |= ((temp<<6)&0xC0); 
//	}

//	function rectangleColorEditing(n, val)
//	{
//		gfxSubtractValModuloInPlace(menuFieldGfx+2/*rect_filled*/+n, val, 0, 65);	// allow for COLOR_NOTSET (-2) so 0 to 65
//	}

//	function rectanglePositionGetX()
//	{
//		return gfxData[menuFieldGfx+4/*rect_x*/];
//	}

//	function rectanglePositionGetY()
//	{
//		return gfxData[menuFieldGfx+5/*rect_y*/];
//	}

//	function rectanglePositionXEditing(val)
//	{
//		gfxSubtractValInPlace(menuFieldGfx+4/*rect_x*/, val, 0, displaySize);
//	}

//	function rectanglePositionYEditing(val)
//	{
//		gfxSubtractValInPlace(menuFieldGfx+5/*rect_y*/, val, 0, displaySize);
//	}

//	function rectanglePositionCentreX()
//	{
//		gfxData[menuFieldGfx+4/*rect_x*/] = displayHalf;
//	}

//	function rectanglePositionCentreY()
//	{
//		gfxData[menuFieldGfx+5/*rect_y*/] = displayHalf;
//	}

//	function rectangleGetWidth()
//	{
//		return gfxData[menuFieldGfx+6/*rect_w*/];
//	}

//	function rectangleWidthEditing(val)
//	{
//		gfxSubtractValInPlace(menuFieldGfx+6/*rect_w*/, val, 1, displaySize);
//	}

//	function rectangleGetHeight()
//	{
//		return gfxData[menuFieldGfx+7/*rect_h*/];
//	}

//	function rectangleHeightEditing(val)
//	{
//		gfxSubtractValInPlace(menuFieldGfx+7/*rect_h*/, val, 1, displaySize);
//	}

	function menuRectangleGetString(fState)
	{
    	if (fState==100/*r_typeEdit*/)
    	{
 			return safeStringFromJsonData(Rez.JsonData.id_ringStrings2, 0, rectangleGetType());
    	}
    	else if (fState==101/*r_directionEdit*/)
    	{
 			return safeStringFromJsonData(Rez.JsonData.id_rectangleStrings, 1, rectangleGetDirection());
    	}
    	else if (fState==105/*r_wEdit*/)
    	{
    		//return "w=" + rectangleGetWidth();
    		return "w=" + gfxData[menuFieldGfx+6/*rect_w*/];
    	}
    	else if (fState==106/*r_hEdit*/)
    	{
    		//return "h=" + rectangleGetHeight();
    		return "h=" + gfxData[menuFieldGfx+7/*rect_h*/];
    	}
    	else if (fState==107/*r_visEdit*/)
    	{
    		return fieldVisibilityString();
    	}
    	else if (fState==111/*r_xEdit*/)
    	{
    		//return "x=" + rectanglePositionGetX();
    		return "x=" + gfxData[menuFieldGfx+4/*rect_x*/];
    	}
    	else if (fState==112/*r_yEdit*/)
    	{
    		//return "y=" + rectanglePositionGetY();
    		return "y=" + gfxData[menuFieldGfx+5/*rect_y*/];
    	}
		else if (fState<=15/*r_tap*/)
		{
 			return safeStringFromJsonData(Rez.JsonData.id_rectangleStrings, 0, fState);
 		}
 		else
 		{
 			return "editing...";	// for x, y, w, h
 		}
	}

	function menuRectangleOnEditing(val, fState)
	{
    	if (fState==100/*r_typeEdit*/)
    	{
 			//rectangleTypeEditing(val);
			//var eDisplay = (rectangleGetType() + val + 1)%1;
	    	var eDisplay = arrayTypeEditingValue(val, rectangleGetType(), Rez.JsonData.id_ringStrings2, 1);
			gfxData[menuFieldGfx+1] &= ~0x3F;
			gfxData[menuFieldGfx+1] |= (eDisplay & 0x3F);
    	}
    	else if (fState==101/*r_directionEdit*/)
    	{
 			//rectangleDirectionEditing(val);
			var temp = gfxSubtractValModulo(rectangleGetDirection(), val, 0, 3);
			gfxData[menuFieldGfx+1] &= ~0xC0;
			gfxData[menuFieldGfx+1] |= ((temp<<6)&0xC0);
    	}
    	else if (fState==102/*r_colorEdit*/ || fState==103/*r_unfilledEdit*/)
    	{
    		//rectangleColorEditing(fState-102/*r_colorEdit*/, val);
			gfxSubtractValModuloInPlace(menuFieldGfx+fState-102/*r_colorEdit*/+2/*rect_filled*/, val, 0, 65);	// allow for COLOR_NOTSET (-2) so 0 to 65
    	}
    	else if (fState==105/*r_wEdit*/)
    	{
    		//rectangleWidthEditing(val);
			gfxSubtractValInPlace(menuFieldGfx+6/*rect_w*/, val, 1, displaySize);
    	}
    	else if (fState==106/*r_hEdit*/)
    	{
    		//rectangleHeightEditing(val);
			gfxSubtractValInPlace(menuFieldGfx+7/*rect_h*/, val, 1, displaySize);
    	}
    	else if (fState==107/*r_visEdit*/)
    	{
    		fieldVisibilityEditing(val);
    	}
    	else if (fState==111/*r_xEdit*/)
    	{
    		//rectanglePositionXEditing(val);
			gfxSubtractValInPlace(menuFieldGfx+4/*rect_x*/, val, 0, displaySize);
    	}
    	else if (fState==112/*r_yEdit*/)
    	{
    		//rectanglePositionYEditing(val);
			gfxSubtractValInPlace(menuFieldGfx+5/*rect_y*/, val, 0, displaySize);
    	}
	}
	
	function menuRectangleOnSelect(fState)
	{
    	if (fState==8/*r_earlier*/)
    	{
    		fieldEarlier();
    	}
    	else if (fState==9/*r_later*/)
    	{
    		fieldLater();
    	}
    	else if (fState==13/*r_xCentre*/)
    	{
    		//rectanglePositionCentreX();
			gfxData[menuFieldGfx+4/*rect_x*/] = displayHalf;
    	}
    	else if (fState==14/*r_yCentre*/)
    	{
    		//rectanglePositionCentreY();
			gfxData[menuFieldGfx+5/*rect_y*/] = displayHalf;
    	}
    	else if (fState==15/*r_tap*/)
    	{
    	}
    	else if (fState<100)
    	{
   			fState += 100;

    		if (fState==102/*r_colorEdit*/ || fState==103/*r_unfilledEdit*/)
	    	{
	    		startColorEditing(menuFieldGfx+fState-102/*r_colorEdit*/+2/*rect_filled*/);
	    	}
    	}
    	
    	return fState;
	}
	
	function ringGetTypeFromGfxIndex(index)
	{
		return (gfxData[index+1]&0x3F);
	}

	function ringGetType()
	{
		return (gfxData[menuFieldGfx+1]&0x3F);
	}

//	function ringTypeEditing(val)
//	{
//		//var eDisplay = ((gfxData[menuFieldGfx+1]&0x3F) + val + 14)%14;
//    	var eDisplay = arrayTypeEditingValue(val, ringGetType(), Rez.JsonData.id_ringStrings2, 1);
//		gfxData[menuFieldGfx+1] &= ~0x3F; 
//		gfxData[menuFieldGfx+1] |= (eDisplay & 0x3F); 
//    }
	
//	function ringGetDirectionAnti()
//	{
//		return ((gfxData[menuFieldGfx+1]&0x40)!=0); 
//	}
	
//	function ringDirectionEditing()
//	{
//		gfxData[menuFieldGfx+1] ^= 0x40;
//		
//		// swap start and end over too
//		var temp = gfxData[menuFieldGfx+3];
//		gfxData[menuFieldGfx+3] = gfxData[menuFieldGfx+4];
//		gfxData[menuFieldGfx+4] = temp;
//	}
	
//	function ringGetLimit100()
//	{
//		return ((gfxData[menuFieldGfx+1]&0x80)!=0); 
//	}
	
//	function ringLimitEditing()
//	{
//		gfxData[menuFieldGfx+1] ^= 0x80;
//	}
	
	function ringGetFont()
	{
		return (gfxData[menuFieldGfx+2/*ring_font*/]&0xFF);
	}
	
//	function ringFontEditing(val)
//	{
//		gfxData[menuFieldGfx+2/*ring_font*/] = (ringGetFont() - val + 25/*SECONDFONT_UNUSED*/)%25/*SECONDFONT_UNUSED*/; 
//		reloadDynamicResources = true;
//	}
	
//	function ringStartEditing(val)
//	{
//		gfxSubtractValModuloInPlace(menuFieldGfx+3, val, 0, 59);
//	}
	
//	function ringEndEditing(val)
//	{
//		gfxSubtractValModuloInPlace(menuFieldGfx+4, val, 0, 59);
//	}
	
//	function ringColorEditing(n, val)
//	{
//		gfxSubtractValModuloInPlace(menuFieldGfx+5+n, val, 0, 65);		// allow for COLOR_NOTSET (-2) so 0 to 65
//	}
	
	function menuRingGetString(fState)
	{
    	if (fState==13/*r_typeEdit*/)
    	{
 			return safeStringFromJsonData(Rez.JsonData.id_ringStrings2, 0, ringGetType());    		
    	}
    	else if (fState==14/*r_fontEdit*/)
    	{
 			return safeStringFromJsonData(Rez.JsonData.id_ringStrings3, -1, ringGetFont());    		
    	}
    	else if (fState==17/*r_directionEdit*/)
    	{
 			//return safeStringFromJsonData(Rez.JsonData.id_ringStrings, 1, ringGetDirectionAnti() ? 1 : 0);
 			return safeStringFromJsonData(Rez.JsonData.id_ringStrings, 1, ((gfxData[menuFieldGfx+1]&0x40)!=0) ? 1 : 0);
    	}
    	else if (fState==18/*r_limitEdit*/)
    	{
 			//return safeStringFromJsonData(Rez.JsonData.id_ringStrings, 2, ringGetLimit100() ? 1 : 0);
 			return safeStringFromJsonData(Rez.JsonData.id_ringStrings, 2, ((gfxData[menuFieldGfx+1]&0x80)!=0) ? 1 : 0);
    	}
    	else if (fState==22/*r_visEdit*/)
    	{
    		return fieldVisibilityString();
    	}
		else if (fState<=12/*r_delete*/)
		{
 			return safeStringFromJsonData(Rez.JsonData.id_ringStrings, 0, fState);
		}
		else
		{
			return "editing...";	// for font, start, end
		}
	}

    function menuRingOnEditing(val, fState)
    {
       	if (fState==13/*r_typeEdit*/)
    	{
    		//ringTypeEditing(val);
	    	var eDisplay = arrayTypeEditingValue(val, ringGetType(), Rez.JsonData.id_ringStrings2, 1);
			gfxData[menuFieldGfx+1] &= ~0x3F; 
			gfxData[menuFieldGfx+1] |= (eDisplay & 0x3F); 
    	}
       	else if (fState==14/*r_fontEdit*/)
    	{
    		//ringFontEditing(val);
			gfxData[menuFieldGfx+2/*ring_font*/] = (ringGetFont() - val + 25/*SECONDFONT_UNUSED*/)%25/*SECONDFONT_UNUSED*/; 
			reloadDynamicResources = true;
    	}
       	else if (fState==15/*r_startEdit*/)
    	{
    		//ringStartEditing(val);
			gfxSubtractValModuloInPlace(menuFieldGfx+3, val, 0, 59);
    	}
       	else if (fState==16/*r_endEdit*/)
    	{
    		//ringEndEditing(val);
			gfxSubtractValModuloInPlace(menuFieldGfx+4, val, 0, 59);
    	}
       	else if (fState==17/*r_directionEdit*/)
    	{
    		//ringDirectionEditing();
			gfxData[menuFieldGfx+1] ^= 0x40;
			
			// swap start and end over too
			var temp = gfxData[menuFieldGfx+3];
			gfxData[menuFieldGfx+3] = gfxData[menuFieldGfx+4];
			gfxData[menuFieldGfx+4] = temp;
    	}
       	else if (fState==18/*r_limitEdit*/)
    	{
    		//ringLimitEditing();
			gfxData[menuFieldGfx+1] ^= 0x80;
    	}
       	//else if (fState==19/*r_colorFilledEdit*/)
    	//{
    	//	ringColorEditing(0, val);
    	//}
       	//else if (fState==20/*r_colorValueEdit*/)
    	//{
    	//	ringColorEditing(1, val);
    	//}
       	//else if (fState==21/*r_colorUnfilledEdit*/)
    	//{
    	//	ringColorEditing(2, val);
    	//}
       	else if (fState>=19/*r_colorFilledEdit*/ && fState<=21/*r_colorUnfilledEdit*/)
    	{
			gfxSubtractValModuloInPlace(menuFieldGfx+fState-19/*r_colorFilledEdit*/+5, val, 0, 65);		// allow for COLOR_NOTSET (-2) so 0 to 65
    	}
       	else if (fState==22/*r_visEdit*/)
    	{
    		fieldVisibilityEditing(val);
    	}
	}
	
    function menuRingOnSelect(fState)
    {
       	if (fState>=19/*r_colorFilledEdit*/ && fState<=21/*r_colorUnfilledEdit*/)
    	{
    		startColorEditing(menuFieldGfx+fState-19/*r_colorFilledEdit*/+5);
    	}
    	else if (fState==10/*r_earlier*/)
    	{
    		fieldEarlier();
    	}
    	else if (fState==11/*r_later*/)
    	{
    		fieldLater();
    	}
    	else if (fState==12/*r_delete*/)
    	{
    		fieldDelete();
    		return new myMenuItemFieldSelect();
    	}

    	return null;
    }

	function secondsGetFont()
	{
		return (gfxData[menuFieldGfx+1]&0xFF);
	}
	
//	function secondsFontEditing(val)
//	{
//		var temp = gfxSubtractValModulo(secondsGetFont(), val, 0, 25/*SECONDFONT_UNUSED*/-1);
//		gfxData[menuFieldGfx+1] &= ~0x00FF; 
//		gfxData[menuFieldGfx+1] |= temp;
//		reloadDynamicResources = true;
//	}

	function secondsGetRefresh()
	{
		return ((gfxData[menuFieldGfx+1]>>8) & 0x03);
	}
	
//	function secondsRefreshEditing(val)
//	{
//		var temp = (secondsGetRefresh() - val + 3)%3;
//		gfxData[menuFieldGfx+1] &= ~(0x03 << 8);
//		gfxData[menuFieldGfx+1] |= (temp<<8); 
//		reloadDynamicResources = true;
//	}
	
//	function secondsColorEditing(n, val)
//	{
//		gfxSubtractValModuloInPlace(menuFieldGfx+2+n, val, 0, 65);		// 0 to 65
//		buildSecondsColorArray(menuFieldGfx);
//	}

	function menuSecondsGetString(fState)
	{
    	if (fState==100/*s_fontEdit*/)
    	{
			return safeStringFromJsonData(Rez.JsonData.id_secondsStrings2, -1, secondsGetFont());
    	}
    	else if (fState==101/*s_refreshEdit*/)
    	{
			return safeStringFromJsonData(Rez.JsonData.id_secondsStrings, 1, secondsGetRefresh());
    	}
    	else if (fState==107/*s_visEdit*/)
    	{
    		return fieldVisibilityString();
    	}
 		else if (fState<100/*s_fontEdit*/)
 		{
 			return safeStringFromJsonData(Rez.JsonData.id_secondsStrings, 0, fState);
 		}
 		else
 		{
 			return "editing...";	// for font
 		}
	}

    function menuSecondsOnEditing(val, fState)
    {
    	if (fState==100/*s_fontEdit*/)
    	{
    		//secondsFontEditing(val);
			var temp = gfxSubtractValModulo(secondsGetFont(), val, 0, 25/*SECONDFONT_UNUSED*/-1);
			gfxData[menuFieldGfx+1] &= ~0x00FF; 
			gfxData[menuFieldGfx+1] |= temp;
			reloadDynamicResources = true;
    	}
    	else if (fState==101/*s_refreshEdit*/)
    	{
    		//secondsRefreshEditing(val);
			var temp = (secondsGetRefresh() - val + 3)%3;
			gfxData[menuFieldGfx+1] &= ~(0x03 << 8);
			gfxData[menuFieldGfx+1] |= (temp<<8); 
			reloadDynamicResources = true;
    	}
    	else if (fState==107/*s_visEdit*/)
    	{
    		fieldVisibilityEditing(val);
    	}
    	else
    	{
    		//secondsColorEditing(fState-102/*s_colorEdit*/, val);
			gfxSubtractValModuloInPlace(menuFieldGfx+fState-102/*s_colorEdit*/+2, val, 0, 65);		// 0 to 65
			buildSecondsColorArray(menuFieldGfx);
    	}
	}
	
    function menuSecondsOnSelect(fState)
    {
    	if (fState>=102/*s_colorEdit*/ && fState<=106/*s_color0Edit*/)
    	{
    		startColorEditing(menuFieldGfx+fState+2-102/*s_colorEdit*/);
    	}
    	else if (fState==8/*s_earlier*/)
    	{
    		fieldEarlier();
    	}
    	else if (fState==9/*s_later*/)
    	{
    		fieldLater();
    	}
    	else if (fState==10/*s_delete*/)
    	{
    		fieldDelete();
    		return new myMenuItemFieldSelect();
    	}
    	
    	return null;
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

    function onEditing(val)
    {
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
	//time with colon
	//steps (text)
	//heart rate (text)
	//battery indicator
	//alarm icon
	//horizontal line
	//vertical line

	var fState;

    function initialize()
    {
    	myMenuItem.initialize();
    	
    	fState = -1;
    }
    
    function getString()
    {
    	if (fState>=0)
    	{
    		return editorView.safeStringFromJsonData(Rez.JsonData.id_quickAddStrings, -1, fState);
    	}
    	
    	return "quick add";
    }
    
    // up=0 down=1 left=2 right=3
    function hasDirection(d)
    {
    	return true;
    }

    function onNext()
    {
    	if (fState>=0)
    	{
    		fState = (fState+1)%7;
    		return null;
    	}
    	else
    	{
   			return new myMenuItemSaveLoadProfile(0);
    	}
    }
    
    function onPrevious()
    {
    	if (fState>=0)
    	{
    		fState = (fState-1+7)%7;
    		return null;
    	}
    	else
    	{
   			return new myMenuItemFieldAdd();
   		}
    }
    
    function onSelect()
    {
    	fState = editorView.menuQuickAddOnSelect(fState);
    
    	return null;
    }
    
    function onBack()
    {
    	if (fState>=0)
    	{
    		fState = -1;
    		return null;
    	}
    	else
    	{
    		return new myMenuItemExitApp();
    	}
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
    		min = 24/*PROFILE_NUM_USER*/;
    		max = editorView.PROFILE_NUM_PRESET + 24/*PROFILE_NUM_USER*/ - 1;
    	}
    	else
    	{
    		min = 0;
    		max = 24/*PROFILE_NUM_USER*/ - 1;
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
				// when loading new gfx from menu, then some stuff needs resetting:	
				editorView.menuFieldGfx = 0;
				editorView.menuElementGfx = 0;
				
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

//    function onNext()
//    {
//    	return null;
//    }
    
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
//		f_2ndTimeHour,		8
//		f_2ndTimeMinute,	9
//		f_moveBarAlert,		10
//		f_dawnDuskMode,		11
//		f_fontSystemCase,	12
//		f_fontUnsupported,	13
//		f_memoryDisplay,	14
//		f_menuhide,			15
//
//		f_backgroundEdit,		100
//		f_foregroundEdit,		101
//		f_menuColorEdit,		102
//		f_menuBorderEdit,		103
//		f_fieldHighlightEdit,	104
//		f_ElementHighlightEdit,	105
//		f_batteryHighEdit,		106
//		f_batteryLowEdit,		107
//		f_2ndTimeHourEdit,		108
//		f_2ndTimeMinuteEdit,	109
//		f_moveBarAlertEdit,		110
//		f_dawnDuskModeEdit,		111
//		f_fontSystemCaseEdit,	112
//		f_fontUnsupportedEdit,	113
//		f_memoryDisplayEdit,	114
//	}

	var fState;

    function initialize()
    {
    	myMenuItem.initialize();

    	fState = 0;
    }
    
    function getString()
    {
		return editorView.menuHeaderGetString(fState);
    }
    
    // up=0 down=1 left=2 right=3
    function hasDirection(d)
    {
    	return editorView.menuHeaderHasDirection(d, fState);
    }

    function onEditing(val)
    {
		if (fState<100/*f_backgroundEdit*/)
		{
			fState = (fState+val+16)%16;
		}
		else
		{
			editorView.menuHeaderOnEditing(val, fState);
		}
    	
    	return null;
    }
    
    function onSelect()
    {
		if (fState<100)
		{
	    	if (fState==15/*f_menuHide*/)
	    	{
				editorView.menuHide = !editorView.menuHide;
			}
			else
			{
				if (fState>=0/*f_background*/ && fState<=5/*f_ElementHighlight*/)
				{
					editorView.startColorEditing(editorView.menuFieldGfx+3+fState);
				}
			
				fState += 100;
			}
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
//		if (fState==12/*f_xEdit*/)
//    	{
//    		return "x=" + editorView.fieldPositionGetX();
//    	}
//		else if (fState==13/*f_yEdit*/)
//    	{
//    		return "y=" + editorView.fieldPositionGetY();
//    	}
//    	else if (fState==14/*f_alignEdit*/)
//    	{
//    		return editorView.safeStringFromJsonData(Rez.JsonData.id_fieldEditStrings, 1, editorView.fieldGetAlignment());
//    	}
//    	else if (fState==15/*f_visEdit*/)
//    	{
//    		return editorView.fieldVisibilityString();
//    	}
//    	else if (fState<=11/*f_tap*/)
//    	{
//    		return editorView.safeStringFromJsonData(Rez.JsonData.id_fieldEditStrings, 0, fState);
//    	}
//    	else
//    	{
//    		return "editing...";	// for x & y position
//    	}
		return editorView.menuFieldEditGetString(fState);
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
    	else
    	{
			editorView.menuFieldEditOnEditing(fState, val);
    	}
//		else if (fState==12/*f_xEdit*/)
//    	{
//    		//editorView.fieldPositionXEditing(val);
//			editorView.gfxSubtractValInPlace(editorView.menuFieldGfx+1, val, 0, editorView.displaySize);
//    	}
//		else if (fState==13/*f_yEdit*/)
//    	{
//    		//editorView.fieldPositionYEditing(val);
//			editorView.gfxSubtractValInPlace(editorView.menuFieldGfx+2, val, 0, editorView.displaySize);
//    	}
//		else if (fState==14/*f_alignEdit*/)
//    	{
//    		//editorView.fieldAlignmentEditing(val);
//			editorView.gfxData[editorView.menuFieldGfx+3] = (editorView.gfxData[editorView.menuFieldGfx+3]+val+3)%3;
//    	}
//		else if (fState==15/*f_visEdit*/)
//    	{
//    		editorView.fieldVisibilityEditing(val);
//    	}

   		return null;
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
	var editingArrayValue;
	var idArrayValue;

    function initialize(id)
    {
    	myMenuItem.initialize();
    	
    	fState = 0;
    	fId = id;
    	
    	//fStringsIndex = [0, 1, 2, 3, 4][fId-2];
    	fStringsIndex = fId-2;
		fNumCustom = [3, 3, 3, 7, 3][fId-2];
    	
//    	if (fId==2)	// large (hour, minute, colon)
//    	{
//    		fStringsIndex = 0;
//    		fNumCustom = 3;
//    	}
//    	else if (fId==3)	// string
//    	{
//    		fStringsIndex = 1;
//    		fNumCustom = 3;
//    	}
//    	else if (fId==4)	// icon
//    	{
//    		fStringsIndex = 2;
//    		fNumCustom = 3;
//    	}
//    	else if (fId==5)	// movebar
//    	{
//    		fStringsIndex = 3;
//    		fNumCustom = 7;
//    	}
//    	else if (fId==6)	// chart
//    	{
//    		fStringsIndex = 4;
//    		fNumCustom = 3;
//    	}
    	
    	idArray = -1;
    	editingArrayValue = false;
    	idArrayValue = 0;
    }
    
    function getString()
    {
		var numTop = fNumCustom+4;

    	if (fState==numTop+fNumCustom)
    	{
    		//return editorView.elementVisibilityString();
			return editorView.getVisibilityString(editorView.menuElementGfx);
    	}
    	else if (fState<numTop)
    	{
    		return editorView.safeStringFromJsonData(Rez.JsonData.id_editElementStrings, fStringsIndex, fState);
    	}
		else if (fId==2 && fState==numTop)	// large type
		{
			return editorView.getLargeTypeName(editorView.stringGetType());
	    }
		else if (fId==2 && fState==numTop+1)	// large font
		{
			var rezArr = [Rez.JsonData.id_editElementLargeFontStrings, Rez.JsonData.id_editElementLargeFontStrings2];
			return editorView.safeStringFromJsonDataMulti(rezArr, editorView.stringGetFont());
	    }
		else if (fId==3 && fState==numTop)	// string type
		{
			if (!editingArrayValue)
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
		else if (fId==4 && fState==numTop)	// icon
		{
    		return editorView.iconGetTypeName();
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
		    		editorView.stringColorEditing(val);
		    	}
		    }
    		else if (fId==3)	// string
    		{
		    	if (fState==numTop)
		    	{
		    		if (!editingArrayValue)
		    		{
		    			idArray = (idArray+val+5)%5;
		    		}
		    		else
		    		{
			    		idArrayValue = editorView.stringTypeEditing(val, idArrayValue, idArray);
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
			    		editingArrayValue = false;
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
    			if (!editingArrayValue)
    			{
    				editingArrayValue = true;
	    			idArrayValue = editorView.stringTypeEditing(0, editorView.stringGetType(), idArray);	// set initial value
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
	    			if (editingArrayValue)
	    			{
		    			editingArrayValue = false;
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
			return editorView.iconGetTypeName();
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
    		//idArrayValue = (idArrayValue+val+3)%3;
    		idArrayValue = editorView.largeTypeEditingValue(val, idArrayValue);
    	}
		else if (fState<=15/*s_valueEdit*/)
		{
    		idArrayValue = editorView.stringTypeEditing(val, idArrayValue, idArray);
    	}
		else if (fState==16/*s_iconEdit*/)
		{
			editorView.iconTypeEditing(val);
    	}
    
    	return null;
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
			//idArrayValue = 0;	// this is just the hour
    		idArrayValue = editorView.largeTypeEditingValue(0, 0);
			fState = 10/*s_largeEdit*/;
		}
		else if (fState<=6/*s_value*/)
		{
			idArray = fState-2;
    		idArrayValue = editorView.stringTypeEditing(0, 0, idArray);		// first value in sub array
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
			index = editorView.gfxAddString(afterIndex, 2, idArrayValue);
		}
		else if (fState<=15/*s_valueEdit*/)
		{
			index = editorView.gfxAddString(afterIndex, 3, idArrayValue);
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
		return editorView.menuRectangleGetString(fState);
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
    	else
    	{
    		editorView.menuRectangleOnEditing(val, fState);
    	}

    	return null;
    }
    
    function onSelect()
    {
    	if (fState==4/*r_position*/)
    	{
    		fState = 11/*r_x*/;
    	}
    	else if (fState==10/*r_delete*/)
    	{
    		editorView.fieldDelete();
    		return new myMenuItemFieldSelect();
    	}
    	else
    	{
    		fState = editorView.menuRectangleOnSelect(fState);
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
		return editorView.menuRingGetString(fState);
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
       	else
    	{
    		editorView.menuRingOnEditing(val, fState);
    	}
    
    	return null;
    }
    
    function onSelect()
    {
    	if (fState<=9/*r_vis*/)
    	{
    		fState += 13;
    	}

    	return editorView.menuRingOnSelect(fState);
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
//		s_font,		0
//		s_refresh,	1
//		s_color,	2
//		s_color5,	3
//		s_color10,	4
//		s_color15,	5
//		s_color0,	6
//		s_vis,		7
//		s_earlier,	8
//		s_later,	9
//		s_delete,	10
//
//		s_fontEdit,		100
//		s_refreshEdit,	101
//		s_colorEdit,	102
//		s_color5Edit,	103
//		s_color10Edit,	104
//		s_color15Edit,	105
//		s_color0Edit,	106
//		s_visEdit,		107
//	}

	var fState;

    function initialize()
    {
    	myMenuItem.initialize();

    	fState = 0;
    }
    
    function getString()
    {
    	return editorView.menuSecondsGetString(fState);
    }
    
    // up=0 down=1 left=2 right=3
    function hasDirection(d)
    {
    	return (d!=3 || fState<100/*s_fontEdit*/);
    }

    function onEditing(val)
    {
    	if (fState<100/*s_fontEdit*/)
    	{
    		fState = (fState+val+11)%11;
    	}
    	else
    	{
    		editorView.menuSecondsOnEditing(val, fState);
    	}
    	    	
    	return null;
    }
    
    function onSelect()
    {
    	if (fState<=7/*s_vis*/)
    	{
    		fState += 100;
		}
		
    	return editorView.menuSecondsOnSelect(fState);
    }
    
    function onBack()
    {
    	if (fState>=100)
    	{
	    	//if (fState>=102/*s_colorEdit*/ && fState<=106/*s_color0Edit*/)
	    	//{
	    		editorView.endColorEditing();
	    	//}

    		fState -= 100;
    	}
    	else
    	{
    		return new myMenuItemFieldSelect();
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
