//------------------|
// Created by Raymix|
//------------------|

private ["_object","_objectSnapGizmo","_objColorActive","_objColorInactive","_classname","_whitelist","_points","_cfg","_cnt","_pos","_findWhitelisted","_nearbyObject","_posNearby","_selectedAction","_newPos","_pointsNearby","_onWater"];
//Args
snapActionState = _this select 3 select 0;
_object = _this select 3 select 1;
_classname = _this select 3 select 2;
_objectHelper = _this select 3 select 3;
_selectedAction = _this select 3 select 4;

//Snap config file
_cfg = (missionConfigFile >> "SnapBuilding" >> _classname);
_whitelist = getArray (_cfg >> "snapTo");
_points = getArray (_cfg >> "points");

//colors
_objColorActive = "#(argb,8,8,3)color(0,0.92,0.06,1,ca)";
_objColorInactive = "#(argb,8,8,3)color(0.04,0.84,0.92,0.3,ca)";

fnc_snapActionCleanup = {
	private ["_s1","_s2","_s3","_cnt"];
	_s1 = _this select 0;
	_s2 = _this select 1;
	_s3 = _this select 2;
	player removeAction s_player_toggleSnap;
	player removeAction s_player_toggleSnapSelect;
	{player removeAction _x;} forEach s_player_toggleSnapSelectPoint;
	if (_s1 > 0) then {
	s_player_toggleSnap = player addaction [format[("<t color=""#ffffff"">" + ("Snap: %1") +"</t>"),snapActionState],"custom\snap_pro\snap_build.sqf",[snapActionState,_object,_classname,_objectHelper],6,false,false];
	};
	if (_s2 > 0) then {
	s_player_toggleSnapSelect = player addaction [format[("<t color=""#ffffff"">" + ("Snap Point: %1") +"</t>"),snapActionStateSelect],"custom\snap_pro\snap_build.sqf",[snapActionStateSelect,_object,_classname,_objectHelper],5,false,false];
	};
	if (_s3 > 0) then {
	s_player_toggleSnapSelectPoint=[];
	_cnt = 0;
	{snapActions = player addaction [format[("<t color=""#ffffff"">" + ("%1)Select: %2") +"</t>"),_cnt,_x select 3],"custom\snap_pro\snap_build.sqf",["Selected",_object,_classname,_objectHelper,_cnt],4,false,true];
	s_player_toggleSnapSelectPoint set [count s_player_toggleSnapSelectPoint,snapActions];
	_cnt = _cnt+1;
	}forEach _points;
	};
};

fnc_initSnapPoints = {
	snapGizmos = [];
{
	_objectSnapGizmo = "Sign_sphere10cm_EP1" createVehicleLocal [0,0,0];
	_objectSnapGizmo setobjecttexture [0,_objColorInactive];
	_objectSnapGizmo attachTo [_object,[_x select 0,_x select 1,_x select 2]];
	snapGizmos set [count snapGizmos,_objectSnapGizmo];
} forEach _points;
};

fnc_initSnapPointsNearby = {
	_pos = getPosATL _object;
	_findWhitelisted = []; _pointsNearby = [];
	_findWhitelisted = nearestObjects [_pos,_whitelist,15]-[_object];
	snapGizmosNearby = [];	
	{	
		_nearbyObject = _x;
		_pointsNearby = getArray (missionConfigFile >> "SnapBuilding" >> (typeOf _x) >> "points");
		{
			_onWater = surfaceIsWater position _nearbyObject;
			_objectSnapGizmo = "Sign_sphere10cm_EP1" createVehicleLocal [0,0,0];
			_objectSnapGizmo setobjecttexture [0,_objColorInactive];
			_posNearby = _nearbyObject modelToWorld [_x select 0,_x select 1,_x select 2];
			if (_onWater) then {
				_objectSnapGizmo setPosASL [(_posNearby) select 0,(_posNearby) select 1,(getPosASL _nearbyObject select 2) + (_x select 2)];
			} else {
				_objectSnapGizmo setPosATL _posNearby;
			};
			_objectSnapGizmo setDir (getDir _nearbyObject);
			snapGizmosNearby set [count snapGizmosNearby,_objectSnapGizmo];
		} forEach _pointsNearby;
	} forEach _findWhitelisted;
};

fnc_initSnapPointsCleanup = {
{detach _x;deleteVehicle _x;}forEach snapGizmos;snapGizmos=[];
{deleteVehicle _x;}forEach snapGizmosNearby;snapGizmosNearby=[];
snapActionState = "OFF";
};

fnc_snapDistanceCheck = {
	while {snapActionState == "ON"} do {
	private ["_distClosestPointFound","_distCheck","_distClosest","_distClosestPoint","_testXPos","_testXDir","_distClosestPointFoundPos","_distClosestPointFoundDir","_distClosestAttached","_distCheckAttached","_distClosestAttachedFoundPos"];
	_distClosestPointFound = objNull; _distCheck = 0; _distClosest = 10; _distClosestPoint = objNull; _testXPos = []; _distClosestPointFoundPos =[]; _distClosestPointFoundDir = 0;
		{	
			if (_x !=_distClosestPointFound) then {_x setobjecttexture [0,_objColorInactive];};
			_testXPos = [(getPosATL _x select 0),(getPosATL _x select 1),(getPosATL _x select 2)];
			_distCheck = _objectHelper distance _testXPos;
			_distClosestPoint = _x;
				if (_distCheck < _distClosest) then {
					_distClosest = _distCheck;
					_distClosestPointFound setobjecttexture [0,_objColorInactive];
					_distClosestPointFound = _x;
					_distClosestPointFound setobjecttexture [0,_objColorActive];
				};
		} forEach snapGizmosNearby;	
		
		if (snapActionStateSelect == "Manual" or snapActionStateSelect == "Selected" ) then {
			if (helperDetach) then {
				_distClosestPointFoundPos = getPosATL _distClosestPointFound;
				_distClosestPointFoundDir = getDir _distClosestPointFound;
				_objectHelper setPosATL _distClosestPointFoundPos;
				_objectHelper setDir _distClosestPointFoundDir;
				waitUntil {sleep 0.1; !helperDetach};
			};
		} else {
			_distClosestAttached = objNull; _distCheckAttached = 0; _distClosest = 10; _distClosestAttachedFoundPos = [];
			{
				if (_x !=_distClosestAttached) then {_x setobjecttexture [0,_objColorInactive];};
				_testXPos = [(getPosATL _x select 0),(getPosATL _x select 1),(getPosATL _x select 2)];
				_distCheckAttached = _distClosestPointFound distance _testXPos;
				_distClosestPoint = _x;
					if (_distCheckAttached < _distClosest) then {
						_distClosest = _distCheckAttached;
						_distClosestAttached setobjecttexture [0,_objColorInactive];
						_distClosestAttached = _x;
						_distClosestAttached setobjecttexture [0,_objColorActive];
					};
			} forEach snapGizmos;
		
			if (helperDetach) then {
				_distClosestPointFoundPos = getPosATL _distClosestPointFound;
				_distClosestPointFoundDir = getDir _distClosestPointFound;
				_distClosestAttachedFoundPos = getPosATL _distClosestAttached;
				detach _object;
				_objectHelper setPosATL _distClosestAttachedFoundPos;
				_object attachTo [_objectHelper];
				_objectHelper setPosATL _distClosestPointFoundPos;
				_objectHelper setDir _distClosestPointFoundDir;
				waitUntil {sleep 0.1; !helperDetach};
			};
		};
		sleep 0.1;
	};
};

switch (snapActionState) do {
	case "Init": {
		snapActionState = "OFF";
		[1,0,0] call fnc_snapActionCleanup;
		/*
			Shows help dialog for player ONCE per log in, explaining controls.
			Add snapHint = false; to your init.sqf to disable this message completely.
		*/
		if (isNil "snapHint") then { 
			_bldTxtClr = "color='#ff8800'"; //orange
			_bldTxtClr2 = "color='#17DBEC'"; //cyan
			_bldTxtStringTitle = parseText format ["<t %1>Snap Building Pro</t>",_bldTxtClr];
			_bldTxtString1 = parseText format ["<t %1>(PgUp or PgDown)</t> to raise or lower the object",_bldTxtClr];
			_bldTxtString2 = parseText format ["Hold <t %1>(ALT or CTRL)</t> + <t %1>(PgUp or PgDown)</t> to change speed of altitude (Works while snapped)",_bldTxtClr];
			_bldTxtString3 = parseText format ["<t %1>(Q or E)</t> to rotate object 180 degrees while holding or +/-45 degrees while Detached/Snapped",_bldTxtClr];
			_bldTxtString4 = parseText format ["<t %1>(Space-Bar)</t> to build your object",_bldTxtClr];
			_bldTxtString5 = parseText format ["<t %2>[Auto Mode]</t> Toggle <t %1>(F)</t> Key to Snap or Pick up object",_bldTxtClr,_bldTxtClr2];
			_bldTxtString6 = parseText format ["<t %2>[Manual Mode]</t> Toggle <t %1>(F)</t> Key to Detach or Pick up object",_bldTxtClr,_bldTxtClr2];
			"" hintC [_bldTxtString1,_bldTxtString2,_bldTxtString3,_bldTxtString4,_bldTxtString5,_bldTxtString6];
			snapHint = false;
		};
	};
	
	case "OFF": {
	snapActionState = "ON"; snapActionStateSelect = "Auto";
	[1,1,0] call fnc_snapActionCleanup;
	call fnc_initSnapPoints;
	call fnc_initSnapPointsNearby;
	call fnc_snapDistanceCheck;
	};
	
	case "ON": {
	//snapActionState = "OFF";
	[1,0,0] call fnc_snapActionCleanup;
	call fnc_initSnapPointsCleanup;
	};
	
	case "Auto": {
	snapActionState = "ON";snapActionStateSelect = "Manual";
	[1,1,1] call fnc_snapActionCleanup;
	call fnc_snapDistanceCheck;
	};
	
	case "Manual": {
	snapActionState = "ON";snapActionStateSelect = "Auto";
	[1,1,0] call fnc_snapActionCleanup;
	call fnc_snapDistanceCheck;
	};
	
	case "Selected": { _cnt = 0; _newPos = [];
{	
	_x setobjecttexture [0,_objColorInactive];
	if (_cnt == _selectedAction) then {
		_newPos = [(getPosATL _x select 0),(getPosATL _x select 1),(getPosATL _x select 2)];
		detach _object;
		detach _objectHelper;
		_objectHelper setPosATL _newPos;
		_object attachTo [_objectHelper];
		_x setobjecttexture [0,_objColorActive];
		if (!helperDetach) then {_objectHelper attachTo [player];};	
	};
	_cnt = _cnt+1;
}forEach snapGizmos;
	};
};
