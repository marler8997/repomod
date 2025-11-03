using BepInEx;
using UnityEngine;

namespace MyFirstMod
{
    [BepInPlugin("com.yourname.myfirstmod", "My First Mod", "1.0.0")]
    public class Plugin : BaseUnityPlugin
    {
        private void Awake()
        {
            Logger.LogInfo("=== MY FIRST MOD LOADED SUCCESSFULLY! ===");
            Debug.Log("Hello from MyFirstMod!");
        }
    }
}
