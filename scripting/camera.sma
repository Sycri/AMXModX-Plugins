#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#pragma semicolon 1

#define USE_TOGGLE 3

new g_PlayerCamera[MAX_PLAYERS + 1];

new g_UsingCamera;
//#define MarkUserUsingCamera(%0)   g_UsingCamera |= 1 << (%0 & 31)
#define ClearUserUsingCamera(%0)    g_UsingCamera &= ~(1 << (%0 & 31))
#define IsUserUsingCamera(%0)       (g_UsingCamera & 1 << (%0 & 31))
#define ToggleUserCameraState(%0)   g_UsingCamera ^= 1 << (%0 & 31)

new g_MaxPlayers;

public plugin_init()
{
    register_plugin("Camera View", "1.0", "ConnorMcLeod");

    register_clcmd("say /cam", "@ClientCommand_Camera");

    g_MaxPlayers = get_maxplayers();
}

public client_disconnected(id)
{
    new ent = g_PlayerCamera[id];
    if(pev_valid(ent))
        engfunc(EngFunc_RemoveEntity, ent);
    
    g_PlayerCamera[id] = 0;
    ClearUserUsingCamera(id);
    checkForwards();
}

public client_putinserver(id)
{
    g_PlayerCamera[id] = 0;
    ClearUserUsingCamera(id);
}

@ClientCommand_Camera(id)
{
    if(!is_user_alive(id))
        return;

    new ent = g_PlayerCamera[id];
    if (!pev_valid(ent)) {
        static triggerCam;
        if(!triggerCam)
            triggerCam = engfunc(EngFunc_AllocString, "trigger_camera");

        ent = engfunc(EngFunc_CreateNamedEntity, triggerCam);
        set_kvd(0, KV_ClassName, "trigger_camera");
        set_kvd(0, KV_fHandled, 0);
        set_kvd(0, KV_KeyName, "wait");
        set_kvd(0, KV_Value, "999999");
        dllfunc(DLLFunc_KeyValue, ent, 0);

        set_pev(ent, pev_spawnflags, SF_CAMERA_PLAYER_TARGET | SF_CAMERA_PLAYER_POSITION);
        set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_ALWAYSTHINK);

        dllfunc(DLLFunc_Spawn, ent);

        g_PlayerCamera[id] = ent;
    }

    ToggleUserCameraState(id);
    checkForwards();

    new Float:maxSpeed, flags = pev(id, pev_flags);
    pev(id, pev_maxspeed, maxSpeed);

    ExecuteHam(Ham_Use, ent, id, id, USE_TOGGLE, 1.0);

    set_pev(id, pev_flags, flags);
    // depending on mod, you may have to send SetClientMaxspeed here.
    // engfunc(EngFunc_SetClientMaxspeed, id, maxSpeed);
    set_pev(id, pev_maxspeed, maxSpeed);
}

@Forward_Camera_Think(ent)
{
    static id;
    if (!(id = get_cam_owner(ent)))
        return;

    static Float:vecPlayerOrigin[3], Float:vecCameraOrigin[3], Float:vecAngles[3], Float:vecBack[3];

    pev(id, pev_origin, vecPlayerOrigin);
    pev(id, pev_view_ofs, vecAngles);
    vecPlayerOrigin[2] += vecAngles[2];

    pev(id, pev_v_angle, vecAngles);

    // See player from front ?
    //fVecAngles[0] = 15.0
    //fVecAngles[1] += fVecAngles[1] > 180.0 ? -180.0 : 180.0

    angle_vector(vecAngles, ANGLEVECTOR_FORWARD, vecBack);

    //Move back to see ourself (150 units)
    vecCameraOrigin[0] = vecPlayerOrigin[0] + (-vecBack[0] * 150.0);
    vecCameraOrigin[1] = vecPlayerOrigin[1] + (-vecBack[1] * 150.0);
    vecCameraOrigin[2] = vecPlayerOrigin[2] + (-vecBack[2] * 150.0);

    engfunc(EngFunc_TraceLine, vecPlayerOrigin, vecCameraOrigin, IGNORE_MONSTERS, id, 0);
    static Float:flFraction;
    get_tr2(0, TR_flFraction, flFraction);
    if (flFraction != 1.0) {// adjust camera place if close to a wall
        flFraction *= 150.0;
        vecCameraOrigin[0] = vecPlayerOrigin[0] + (-vecBack[0] * flFraction);
        vecCameraOrigin[1] = vecPlayerOrigin[1] + (-vecBack[1] * flFraction);
        vecCameraOrigin[2] = vecPlayerOrigin[2] + (-vecBack[2] * flFraction);
    }

    set_pev(ent, pev_origin, vecCameraOrigin);
    set_pev(ent, pev_angles, vecAngles);
}

get_cam_owner(ent)
{
    static id;
    for (id = 1; id <= g_MaxPlayers; id++) {
        if (g_PlayerCamera[id] == ent)
            return id;
    }
    return 0;
}

@Forward_SetView(id, ent)
{
    if (IsUserUsingCamera(id) && is_user_alive(id)) {
        new cam = g_PlayerCamera[id];
        if (cam && ent != cam) {
            new className[16];
            pev(ent, pev_classname, className, charsmax(className));
            
            if (!equal(className, "trigger_camera")) {// should let real cams enabled
                engfunc(EngFunc_SetView, id, cam); // shouldn't be always needed
                return FMRES_SUPERCEDE;
            }
        }
    }
    return FMRES_IGNORED;
}

checkForwards()
{
    static HamHook:cameraThink, setView;
    if (g_UsingCamera) {
        if(!setView)
            setView = register_forward(FM_SetView, "@Forward_SetView");
            
        if(!cameraThink)
            cameraThink = RegisterHam(Ham_Think, "trigger_camera", "@Forward_Camera_Think");
        else
            EnableHamForward(cameraThink);
    } else {
        if (setView) {
            unregister_forward(FM_SetView, setView);
            setView = 0;
        }

        if (cameraThink)
            DisableHamForward(cameraThink);
    }
}
