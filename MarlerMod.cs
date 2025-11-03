using BepInEx;
using BepInEx.Logging;
using UnityEngine;
using HarmonyLib;
using System;

namespace MarlerMod
{
    [BepInPlugin("com.marler.upgrademod", "Marler Upgrade Mod", "1.0.0")]
    public class Plugin : BaseUnityPlugin
    {
        private static ManualLogSource logger;
        private static bool commandsRegistered = false;  // Prevent duplicate registration

        private void Awake()
        {
            logger = Logger;
            Logger.LogInfo("=== MARLER UPGRADE MOD LOADED ===");

            try
            {
                Logger.LogInfo("Applying Harmony patches...");
                Harmony harmony = new Harmony("com.marler.upgrademod");
                harmony.PatchAll();
                Logger.LogInfo("Harmony patches applied!");
            }
            catch (Exception e)
            {
                Logger.LogError("Failed to apply Harmony patches: " + e.Message);
                Logger.LogError(e.StackTrace);
            }
        }

        [HarmonyPatch(typeof(DebugCommandHandler))]
        [HarmonyPatch("Awake")]
        public class DebugCommandHandler_Awake_Patch
        {
            static void Postfix()
            {
                if (commandsRegistered)
                {
                    logger.LogInfo("Commands already registered, skipping...");
                    return;
                }

                logger.LogInfo("DebugCommandHandler.Awake() called - registering our commands!");

                try
                {
                    RegisterUpgradeCommands();
                    commandsRegistered = true;
                }
                catch (Exception e)
                {
                    logger.LogError("Failed in postfix: " + e.Message);
                    logger.LogError(e.StackTrace);
                }
            }
        }

        private static void RegisterUpgradeCommands()
        {
            logger.LogInfo("RegisterUpgradeCommands() started");

            try
            {
                DebugCommandHandler.ChatCommand sprintCmd = new DebugCommandHandler.ChatCommand(
                    "sprint",
                    "Set sprint upgrade level. Usage: sprint <level>",
                    new Action<bool, string[]>(ExecuteSprintCommand),
                    null, null, false
                );
                DebugCommandHandler.instance.Register(sprintCmd);
                logger.LogInfo("Sprint command registered!");

                DebugCommandHandler.ChatCommand staminaCmd = new DebugCommandHandler.ChatCommand(
                    "stamina",
                    "Set stamina upgrade level. Usage: stamina <level>",
                    new Action<bool, string[]>(ExecuteStaminaCommand),
                    null, null, false
                );
                DebugCommandHandler.instance.Register(staminaCmd);
                logger.LogInfo("Stamina command registered!");

                DebugCommandHandler.ChatCommand healthCmd = new DebugCommandHandler.ChatCommand(
                    "health",
                    "Set health upgrade level. Usage: health <level>",
                    new Action<bool, string[]>(ExecuteHealthCommand),
                    null, null, false
                );
                DebugCommandHandler.instance.Register(healthCmd);
                logger.LogInfo("Health command registered!");

                logger.LogInfo("All commands registered successfully!");
            }
            catch (Exception e)
            {
                logger.LogError("Failed to register commands: " + e.Message);
                logger.LogError(e.StackTrace);
            }
        }

        enum UpgradeKind {
            sprint,
            stamina,
            health,
        };
        private static void ExecuteUpgradeCommand(UpgradeKind kind, string[] args)
        {
            string steamID = GetLocalPlayerSteamID();
            logger.LogInfo("Using Steam ID: " + steamID);
            if (string.IsNullOrEmpty(steamID))
            {
                // TODO: include why it failed
                SendConsoleResponse("failed to get steam ID");
                return;
            }

            if (args.Length < 1) {
                SendConsoleResponse("Usage: " +  kind.ToString() + " <level>");
                return;
            }

            string level_string = args[0];
            int desired_level;
            if (!int.TryParse(level_string, out desired_level))
            {
                SendConsoleResponse("ERROR: '" + level_string + "' is not an integer");
                return;
            }

            int current_level;
            try {
                current_level = Upgrade(kind, steamID, 0);
            } catch (Exception e) {
                logger.LogError("Error: " + e.Message);
                logger.LogError(e.StackTrace);
                SendConsoleResponse("ERROR: upgrade API (to get current level) threw an exception!");
                return;
            }

            int diff = desired_level - current_level;
            int new_level;
            try {
                new_level = Upgrade(kind, steamID, diff);
            } catch (Exception e) {
                logger.LogError("Error: " + e.Message);
                logger.LogError(e.StackTrace);
                SendConsoleResponse("ERROR: upgrade API (to set new level) threw an exception!");
                return;
            }
            if (new_level == desired_level) {
                logger.LogInfo(string.Format("SUCCESS: {0} set to level {1}", kind, desired_level));
            } else {
                logger.LogInfo(string.Format("FAIL: {0} set to level {1} returned {2}", kind, desired_level, new_level));
            }
        }


        private static int Upgrade(UpgradeKind kind, string steamID, int change)
        {
            switch (kind) {
                case UpgradeKind.sprint: return PunManager.instance.UpgradePlayerSprintSpeed(steamID, change);
                case UpgradeKind.stamina: return PunManager.instance.UpgradePlayerEnergy(steamID, change);
                case UpgradeKind.health: return PunManager.instance.UpgradePlayerHealth(steamID, change);
                default: throw new InvalidOperationException();
            }
        }

        private static void ExecuteSprintCommand(bool fromServer, string[] args)
        {
            ExecuteUpgradeCommand(UpgradeKind.sprint, args);
        }

        private static void ExecuteStaminaCommand(bool fromServer, string[] args)
        {
            ExecuteUpgradeCommand(UpgradeKind.stamina, args);
        }

        private static void ExecuteHealthCommand(bool fromServer, string[] args)
        {
            ExecuteUpgradeCommand(UpgradeKind.health, args);
        }

        private static void SendConsoleResponse(string message)
        {
            // TODO: actually implment sending the response to the console
            logger.LogInfo("TODO: Console message: " + message);
        }

        private static string GetLocalPlayerSteamID()
        {
            // Method 0: Inspect PunManager structure
            try
            {
                System.Reflection.FieldInfo[] allFields = typeof(PunManager).GetFields(
                    System.Reflection.BindingFlags.Public |
                    System.Reflection.BindingFlags.NonPublic |
                    System.Reflection.BindingFlags.Instance |
                    System.Reflection.BindingFlags.Static);

                logger.LogInfo("PunManager fields:");
                foreach (var field in allFields)
                {
                    logger.LogInfo("  " + field.FieldType.Name + " " + field.Name);

                    // If it's a dictionary or list, try to get its contents
                    if (PunManager.instance != null)
                    {
                        object value = field.GetValue(PunManager.instance);
                        if (value != null)
                        {
                            logger.LogInfo("    Value: " + value.ToString());
                        }
                    }
                }

                // Check all properties
                System.Reflection.PropertyInfo[] allProps = typeof(PunManager).GetProperties(
                    System.Reflection.BindingFlags.Public |
                    System.Reflection.BindingFlags.NonPublic |
                    System.Reflection.BindingFlags.Instance |
                    System.Reflection.BindingFlags.Static);

                logger.LogInfo("PunManager properties:");
                foreach (var prop in allProps)
                {
                    logger.LogInfo("  " + prop.PropertyType.Name + " " + prop.Name);
                }
            }
            catch (Exception e)
            {
                logger.LogError("Inspection failed: " + e.Message);
                logger.LogError(e.StackTrace);
            }

            // Method 1: Try to get local player's Photon view owner
            try
            {
                PlayerController[] players = UnityEngine.Object.FindObjectsOfType<PlayerController>();
                logger.LogInfo("Found " + players.Length + " PlayerControllers");

                foreach (PlayerController player in players)
                {
                    // Check if this player has a PhotonView
                    Photon.Pun.PhotonView photonView = player.GetComponent<Photon.Pun.PhotonView>();
                    if (photonView != null)
                    {
                        logger.LogInfo("Found PhotonView on player");
                        logger.LogInfo("  IsMine: " + photonView.IsMine);
                        logger.LogInfo("  Owner: " + (photonView.Owner != null ? photonView.Owner.NickName : "null"));

                        if (photonView.IsMine && photonView.Owner != null)
                        {
                            logger.LogInfo("  Owner UserId: " + photonView.Owner.UserId);

                            // The UserId might be the Steam ID
                            return photonView.Owner.UserId;
                        }
                    }
                }
            }
            catch (Exception e)
            {
                logger.LogInfo("PhotonView method failed: " + e.Message);
            }

            // Method 2: From SteamManager using reflection
            try
            {
                System.Type steamManagerType = System.Type.GetType("Steamworks.SteamManager, Assembly-CSharp");
                if (steamManagerType != null)
                {
                    object initialized = steamManagerType.GetProperty("Initialized").GetValue(null, null);
                    if ((bool)initialized)
                    {
                        System.Type steamUserType = System.Type.GetType("Steamworks.SteamUser, Assembly-CSharp");
                        object steamID = steamUserType.GetMethod("GetSteamID").Invoke(null, null);
                        string id = steamID.ToString();
                        logger.LogInfo("Got Steam ID from SteamManager: " + id);
                        return id;
                    }
                }
            }
            catch (Exception e)
            {
                logger.LogInfo("SteamManager method failed: " + e.Message);
            }

            logger.LogWarning("All methods failed to get Steam ID");
            return "";
        }
    }
}
