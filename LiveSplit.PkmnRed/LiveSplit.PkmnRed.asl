//Thanks to 
//Spiraster - for making the base of this code and helping me figure out how to edit it
//NieDzejkob - for finding new ram address for HoF fade
//Mango Kangaroo - for providing savestates, route info, and testing the script
//legendeater - for providing another savestate for testing

state("gambatte") {}
state("gambatte_qt") {}

//[3:01 AM] Altafen: don't know offhand how to check category name but it's probably a field on the timer object (if that exists.. never used it)(edited)
//[3:11 AM] Altafen: looks like you get a LiveSplitState timer var -> timer.run.CategoryName gets you the category if you wanted to switch modes automatically
//[3:12 AM] Altafen: found in LiveSplit.Core/Model/... and LiveSplit.ScriptableAutoSplit/ASL/ASLMethod.cs




startup
{
    //-------------------------------------------------------------//

   
    vars.idManip = false;
    vars.bugCounter =  "1"; 
    vars.bugWait = "go";
    vars.foughtRival = false;
    vars.foughtPika = false;
    vars.foughtBugCatcher1 = false;
    vars.foughtBugCatcher2 = false;
    vars.foughtBugCatcher3 = false;

    
    
    settings.Add("glitchless", false, "Glitchless Splits");
    settings.CurrentDefaultParent = "glitchless";

    settings.Add("nidoran", true, "Catch Nidoran");
    settings.Add("enterMtMoon", true, "Enter Mt. Moon");
    settings.Add("exitMtMoon", true, "Exit Mt. Moon");
    settings.Add("nuggetBridge", true, "Nugget Bridge");
    settings.Add("hm02", true, "Obtain HM02");
    settings.Add("flute", true, "Obtain Poké Flute");
    settings.Add("silphGiovanni", true, "Silph Co. (Giovanni)");
    settings.Add("exitVictoryRoad", true, "Exit Victory Road");        
    settings.Add("gymLeaders", false, "Gym Leaders");
    settings.CurrentDefaultParent = "gymLeaders";
    settings.Add("gym1", true, "Pewter Gym (Brock)");
    settings.Add("gym2", true, "Cerulean Gym (Misty)");
    settings.Add("gym3", true, "Vermilion Gym (Lt. Surge)");
    settings.Add("gym4", true, "Celadon Gym (Erika)");
    settings.Add("gym5", true, "Fuchsia Gym (Koga)");
    settings.Add("gym6", true, "Saffron Gym (Sabrina)");
    settings.Add("gym7", true, "Cinnabar Gym (Blaine)");
    settings.Add("gym8", true, "Viridian Gym (Giovanni)");
    settings.CurrentDefaultParent = "glitchless";   
    settings.Add("elite4", true, "Elite 4");
    settings.CurrentDefaultParent = "elite4";
    settings.Add("elite4_1", true, "Lorelei");
    settings.Add("elite4_2", true, "Bruno");
    settings.Add("elite4_3", true, "Agatha");
    settings.Add("elite4_4", true, "Lance");
    settings.Add("elite4_5", true, "Champion");
    settings.Add("hofFade", true, "HoF Fade Out (Final Split)");

    
    settings.CurrentDefaultParent = null;
    
    
    settings.Add("nsc", false, "Any% NSC");
    settings.SetToolTip("nsc", "This route works for the route as of 7/15/2018 https://docs.google.com/document/d/14Vep4XZ-46nNPb5r2bK3QNut6G8DHzwe8tkZyTZnJrU/edit");
    settings.CurrentDefaultParent = "nsc";
   
    
    settings.Add("starter", true, "Got a Starter");      
    settings.Add("rivalFight", true, "Fought Rival");      
    settings.Add("getParcel", true, "Got Oak's Parcel");
    settings.Add("giveParcel", true, "Gave Parcel to Oak");
    settings.Add("getPokeball", true, "Bought a Pokeball");
    settings.Add("spearow", true, "Caught Spearow");     
    settings.Add("depositStarter", true, "Deposited Starter");      
    settings.Add("pikaBattle", true, "Pikachu Battle");  
    settings.Add("Bug Catchers");
    settings.CurrentDefaultParent = "Bug Catchers";    
    settings.Add("bugCatcher1", true, "Fought Bug Catcher 1");
    settings.Add("bugCatcher2", true, "Fought Bug Catcher 2");
    settings.Add("bugCatcher3", true, "Fought Bug Catcher 3");
    settings.CurrentDefaultParent = "nsc";
    settings.Add("hofFadeNSC", true, "HoF Fade Out (Final Split) for NSC");

    
    settings.SetToolTip("starter", "Splits when you get a starter and it asks for a nickname");
    settings.SetToolTip("rivalFight", "");
    settings.SetToolTip("getParcel", "");
    settings.SetToolTip("giveParcel", "");
    settings.SetToolTip("getPokeball", "");
    settings.SetToolTip("spearow", "Splits when you catch spearow and it asks for a nickname");
    settings.SetToolTip("depositStarter", "");
    settings.SetToolTip("Bug Catchers", "Splits when the winning music starts playing");
    settings.SetToolTip("pikaBattle", "");

    settings.SetToolTip("hofFadeNSC", "Splits on full fade to white");
    
    
    


    settings.CurrentDefaultParent = null;


    
    //-------------------------------------------------------------//

    
    vars.stopwatch = new Stopwatch();

    vars.timer_OnStart = (EventHandler)((s, e) =>
    {
        vars.splits = vars.GetSplitList();
    });
    timer.OnStart += vars.timer_OnStart;

    vars.FindOffsets = (Action<Process>)((proc) => 
    {
        if (vars.ptrOffset == IntPtr.Zero)
        {
            print("[Autosplitter] Scanning memory");
            var target = new SigScanTarget(0, "05 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 ?? ?? ?? ?? ?? ?? ?? ?? F8 00 00 00");

            var ptrOffset = IntPtr.Zero;
            foreach (var page in proc.MemoryPages())
            {
                var scanner = new SignatureScanner(proc, page.BaseAddress, (int)page.RegionSize);

                if ((ptrOffset = scanner.Scan(target)) != IntPtr.Zero)
                    break;
            }

            vars.ptrOffset = ptrOffset;
            vars.hramOffset = vars.ptrOffset + 0x1E0;
            vars.wramPtr = new MemoryWatcher<int>(vars.ptrOffset - 0x20);
        }

        if (vars.ptrOffset != IntPtr.Zero)
        {
            vars.wramPtr.Update(proc);
            vars.wramOffset = (IntPtr)vars.wramPtr.Current;
        }

        if (vars.wramOffset != IntPtr.Zero && vars.hramOffset != IntPtr.Zero)
        {
            print("[Autosplitter] WRAM: " + vars.wramOffset.ToString("X8"));
            print("[Autosplitter] HRAM: " + vars.hramOffset.ToString("X8"));
        }
    });

    vars.GetWatcherList = (Func<IntPtr, IntPtr, MemoryWatcherList>)((wramOffset, hramOffset) =>
    {   
        return new MemoryWatcherList
        {
            //WRAM
            new MemoryWatcher<byte>(wramOffset + 0x0001) { Name = "soundID" },
            new MemoryWatcher<uint>(wramOffset + 0x03C9) { Name = "fileSelectTiles" },
            new MemoryWatcher<uint>(wramOffset + 0x0477) { Name = "resetTiles" },
            new MemoryWatcher<uint>(wramOffset + 0x0D40) { Name = "hofPlayerShown" },
            new MemoryWatcher<byte>(wramOffset + 0x0FD8) { Name = "opponentPkmn" },
            new MemoryWatcher<uint>(wramOffset + 0x0FDA) { Name = "opponentPkmnName" },
            new MemoryWatcher<uint>(wramOffset + 0x104A) { Name = "opponentName" },
            new MemoryWatcher<byte>(wramOffset + 0x1163) { Name = "partyCount" },
            new MemoryWatcher<byte>(wramOffset + 0x135E) { Name = "mapIndex" },
            new MemoryWatcher<ushort>(wramOffset + 0x1361) { Name = "playerPos" },
            new MemoryWatcher<ushort>(wramOffset + 0x1FD7) { Name = "hofFadeTimerGlitchless" },
            new MemoryWatcher<ushort>(wramOffset + 0x1FFD) { Name = "state" },       
            
            new MemoryWatcher<byte>(wramOffset + 0x1164) { Name = "pkmn0" },
            new MemoryWatcher<byte>(wramOffset + 0x1165) { Name = "pkmn1" },
            new MemoryWatcher<byte>(wramOffset + 0x1166) { Name = "pkmn2" },
            new MemoryWatcher<byte>(wramOffset + 0x1167) { Name = "pkmn3" },
            new MemoryWatcher<byte>(wramOffset + 0x1168) { Name = "pkmn4" },
            new MemoryWatcher<byte>(wramOffset + 0x1169) { Name = "pkmn5" },
            new MemoryWatcher<byte>(wramOffset + 0x1359) { Name = "idPart1" },
                             //0xD359 - 0xC000 = 0x1359
            new MemoryWatcher<byte>(wramOffset + 0x135A) { Name = "idPart2" },
            new MemoryWatcher<byte>(wramOffset + 0x131E) { Name = "item1" },
            new MemoryWatcher<byte>(wramOffset + 0x131D) { Name = "numberItems" },
            
            new MemoryWatcher<uint>(wramOffset + 0x134A) { Name = "rivalName" },
            new MemoryWatcher<byte>(wramOffset + 0x0026) { Name = "musicTrack" }, //c026
            new MemoryWatcher<byte>(wramOffset + 0x00EF) { Name = "musicBank" }, //C0EF 

            
            new MemoryWatcher<ushort>(wramOffset + 0x1FBF) { Name = "hofFadeTimerNSC" },


            
            //HRAM  
            new MemoryWatcher<byte>(hramOffset + 0x33) { Name = "input" },         
        };
    });

    vars.GetSplitList = (Func<List<Tuple<string, List<Tuple<string, uint>>>>>)(() =>
    {
        return new List<Tuple<string, List<Tuple<string, uint>>>>
        {
           
            Tuple.Create("starter", new List<Tuple<string, uint>> { Tuple.Create("pkmn0", 0xB0u) }),  // charmander       
            Tuple.Create("starter", new List<Tuple<string, uint>> { Tuple.Create("pkmn0", 0xB1u) }), // Squirtle        
            Tuple.Create("starter", new List<Tuple<string, uint>> { Tuple.Create("pkmn0", 0x99u) }), // Bulbasuar              
            Tuple.Create("getParcel", new List<Tuple<string, uint>> { Tuple.Create("item1", 70u) }),                             
            Tuple.Create("getPokeball", new List<Tuple<string, uint>> { Tuple.Create("item1", 4u) }),         
            Tuple.Create("spearow", new List<Tuple<string, uint>> { Tuple.Create("pkmn1", 0x05u) }),
       

            //pika
            Tuple.Create("pikaBattle", new List<Tuple<string, uint>> { Tuple.Create("opponentPkmn", 84u), Tuple.Create("state", 0x03AEu) }),
  



            Tuple.Create("hofFadeNSC", new List<Tuple<string, uint>> { Tuple.Create("mapIndex", 0x76u), Tuple.Create("hofPlayerShown", 1u), Tuple.Create("hofFadeTimerNSC", 0x0108u) }),


            
            Tuple.Create("nidoran", new List<Tuple<string, uint>> { Tuple.Create("partyCount", 2u), Tuple.Create("state", 0x03AEu) }),
            Tuple.Create("enterMtMoon", new List<Tuple<string, uint>> { Tuple.Create("mapIndex", 0x3Bu), Tuple.Create("playerPos", 0x0E23u) }),
            Tuple.Create("exitMtMoon", new List<Tuple<string, uint>> { Tuple.Create("mapIndex", 0x0Fu), Tuple.Create("playerPos", 0x1805u) }),
            Tuple.Create("nuggetBridge", new List<Tuple<string, uint>> { Tuple.Create("opponentName", 0x8A828E91), Tuple.Create("mapIndex", 0x23u), Tuple.Create("opponentPkmn", 0u), Tuple.Create("state", 0x03AEu) }),
            Tuple.Create("hm02", new List<Tuple<string, uint>> { Tuple.Create("soundID", 0x94u), Tuple.Create("mapIndex", 0xBCu) }),
            Tuple.Create("flute", new List<Tuple<string, uint>> { Tuple.Create("soundID", 0x94u), Tuple.Create("mapIndex", 0x95u) }),
            Tuple.Create("silphGiovanni", new List<Tuple<string, uint>> { Tuple.Create("opponentName", 0x958E8886), Tuple.Create("mapIndex", 0xEBu), Tuple.Create("opponentPkmn", 0u), Tuple.Create("state", 0x03AEu) }),
            Tuple.Create("exitVictoryRoad", new List<Tuple<string, uint>> { Tuple.Create("mapIndex", 0x22u), Tuple.Create("playerPos", 0x0E1Fu) }),
            Tuple.Create("gym1", new List<Tuple<string, uint>> { Tuple.Create("opponentName", 0x828E9181), Tuple.Create("opponentPkmn", 0u), Tuple.Create("state", 0x03AEu) }),
            Tuple.Create("gym2", new List<Tuple<string, uint>> { Tuple.Create("opponentName", 0x9392888C), Tuple.Create("opponentPkmn", 0u), Tuple.Create("state", 0x03AEu) }),
            Tuple.Create("gym3", new List<Tuple<string, uint>> { Tuple.Create("opponentName", 0x92E8938B), Tuple.Create("opponentPkmn", 0u), Tuple.Create("state", 0x03AEu) }),
            Tuple.Create("gym4", new List<Tuple<string, uint>> { Tuple.Create("opponentName", 0x8A889184), Tuple.Create("opponentPkmn", 0u), Tuple.Create("state", 0x03AEu) }),
            Tuple.Create("gym5", new List<Tuple<string, uint>> { Tuple.Create("opponentName", 0x80868E8A), Tuple.Create("opponentPkmn", 0u), Tuple.Create("state", 0x03AEu) }),
            Tuple.Create("gym6", new List<Tuple<string, uint>> { Tuple.Create("opponentName", 0x91818092), Tuple.Create("opponentPkmn", 0u), Tuple.Create("state", 0x03AEu) }),
            Tuple.Create("gym7", new List<Tuple<string, uint>> { Tuple.Create("opponentName", 0x88808B81), Tuple.Create("opponentPkmn", 0u), Tuple.Create("state", 0x03AEu) }),
            Tuple.Create("gym8", new List<Tuple<string, uint>> { Tuple.Create("opponentName", 0x958E8886), Tuple.Create("mapIndex", 0x2Du), Tuple.Create("opponentPkmn", 0u), Tuple.Create("state", 0x03AEu) }),
            Tuple.Create("elite4_1", new List<Tuple<string, uint>> { Tuple.Create("opponentName", 0x84918E8B), Tuple.Create("opponentPkmn", 0u), Tuple.Create("state", 0x03AEu) }), //Tuple.Create("mapIndex", 0xF5u)                                                                   
            Tuple.Create("elite4_2", new List<Tuple<string, uint>> { Tuple.Create("opponentName", 0x8D949181), Tuple.Create("opponentPkmn", 0u), Tuple.Create("state", 0x03AEu) }), //Tuple.Create("mapIndex", 0xF6u)
            Tuple.Create("elite4_3", new List<Tuple<string, uint>> { Tuple.Create("opponentName", 0x93808680), Tuple.Create("opponentPkmn", 0u), Tuple.Create("state", 0x03AEu) }), //Tuple.Create("mapIndex", 0xF7u)
            Tuple.Create("elite4_4", new List<Tuple<string, uint>> { Tuple.Create("opponentName", 0x828D808B), Tuple.Create("opponentPkmn", 0u), Tuple.Create("state", 0x03AEu) }), //Tuple.Create("mapIndex", 0x71u)
            Tuple.Create("elite4_5", new List<Tuple<string, uint>> { Tuple.Create("opponentPkmnName", 0x948D8495), Tuple.Create("mapIndex", 0x78u), Tuple.Create("opponentPkmn", 0u), Tuple.Create("state", 0x03AEu) }),
            Tuple.Create("hofFade", new List<Tuple<string, uint>> { Tuple.Create("mapIndex", 0x76u), Tuple.Create("hofPlayerShown", 1u), Tuple.Create("hofFadeTimerGlitchless", 0x0108u) }),

           
        };
    });
}

init
{
    vars.idManip = false;
    vars.bugCounter =  "1"; 
    vars.bugWait = "go";
    vars.foughtRival = false;
    vars.foughtPika = false;
    vars.foughtBugCatcher1 = false;
    vars.foughtBugCatcher2 = false;
    vars.foughtBugCatcher3 = false;
    
    
    
     
    vars.ptrOffset = IntPtr.Zero;
    vars.wramOffset = IntPtr.Zero;
    vars.hramOffset = IntPtr.Zero;    
    vars.wramPtr = new MemoryWatcher<byte>(IntPtr.Zero);
    vars.watchers = new MemoryWatcherList();
    vars.splits = new List<Tuple<string, List<Tuple<string, uint>>>>();
    vars.stopwatch.Restart();
}

update
{

    if (vars.stopwatch.ElapsedMilliseconds > 1500) {
        vars.FindOffsets(game);
        if (vars.wramOffset != IntPtr.Zero && vars.hramOffset != IntPtr.Zero)
        {
            vars.watchers = vars.GetWatcherList(vars.wramOffset, vars.hramOffset);
            vars.stopwatch.Reset();
        }
        else {
            vars.stopwatch.Restart();
            return false;
        }
    }
    else if (vars.watchers.Count == 0)
        return false;

    vars.wramPtr.Update(game);

    if (vars.wramPtr.Changed)
    {
        vars.FindOffsets(game);
        vars.watchers = vars.GetWatcherList(vars.wramOffset, vars.hramOffset);
    }

    vars.watchers.UpdateAll(game);
}

start
{   
    vars.idManip = false;
    vars.bugCounter =  "1"; 
    vars.bugWait = "go";
    vars.foughtRival = false;
    vars.foughtPika = false;
    vars.foughtBugCatcher1 = false;
    vars.foughtBugCatcher2 = false;
    vars.foughtBugCatcher3 = false;
    
    return (vars.watchers["input"].Current & 0x09) != 0 && vars.watchers["fileSelectTiles"].Current == 0x96848DED && vars.watchers["state"].Current == 0x5B91;
}

reset
{
    return (vars.watchers["input"].Current & 0x01) != 0 && vars.watchers["resetTiles"].Current == 0x928498ED;
    
}

split
{


vars.rivalName = vars.watchers["rivalName"].Current.ToString();
vars.opponentName = vars.watchers["opponentName"].Current.ToString();


//
//// Checks if you got trainer ID manip for NSC 61896  F1C8
//if (vars.idManip == false) {
//vars.trainerID = (vars.watchers["idPart1"].Current + " " + vars.watchers["idPart2"].Current );
////print("vars.trainerID = " + vars.trainerID );
// if (vars.trainerID == "241 200") {
// //print("success");
// vars.idManip = true ;}
//    else {  
//   // print("Trainer ID Manip Wrong");
//    }}
//


//if you win or lose rival fight then split   // do if setting rival
if (settings["rivalFight"] == true) {
if (vars.foughtRival == false && vars.rivalName.ToString() != "0" && vars.opponentName.ToString() != "0" && vars.opponentName.ToString() == vars.rivalName.ToString() && vars.watchers["opponentPkmn"].Current == 0u &&  vars.watchers["state"].Current == 0x03AEu){
vars.foughtRival = true;
print("[Autosplitter] CustomSplit: Fought Rival");
return true; //split
}}


//Checks if you already have Oak's Parcel and splits when you give it to Oak 
if (vars.watchers["item1"].Old == 70u && vars.watchers["item1"].Current == 255u){
print("[Autosplitter] CustomSplit: Gave Oak's Parcel");
return true; //split
}




//splits when starter pokemon is dropped off
if (settings["depositStarter"] == true) {
if ((vars.watchers["pkmn0"].Old == 0xB0u ||  vars.watchers["pkmn0"].Old == 0xB1u ||  vars.watchers["pkmn0"].Old == 0x99u) && vars.watchers["pkmn0"].Current != 255 && vars.watchers["pkmn0"].Current != 0 && vars.watchers["pkmn0"].Current != 0xB0u &&  vars.watchers["pkmn0"].Current != 0xB1u &&  vars.watchers["pkmn0"].Current != 0x99u) {
print("[Autosplitter] CustomSplit: Deposited Started");
return true; //split
}}



if (settings["Bug Catchers"] == true) {

if (vars.bugWait.ToString() == "go" && vars.bugCounter.ToString() ==  "1" ){
if (vars.watchers["opponentName"].Current.ToString("X") == "7F869481" && vars.watchers["musicTrack"].Current.ToString("X") == "F6" ) {
print("Bug Catcher " + vars.bugCounter.ToString());
vars.bugWait = "wait";
if (settings["bugCatcher1"] == true) {
print("[Autosplitter] CustomSplit: Beat Bug Catcher 1");
return true; //split
}
}}



if (vars.bugCounter.ToString() == "1" && vars.bugWait.ToString() == "wait" && vars.watchers["opponentName"].Current.ToString("X") == "7F869481" && vars.watchers["musicTrack"].Current.ToString("X") == "ED" ) {  
    vars.bugWait = "go";
    vars.bugCounter =  "2" ;
  }
  
  
if (vars.bugWait.ToString() == "go" && vars.bugCounter.ToString() ==  "2" ){
if (vars.watchers["opponentName"].Current.ToString("X") == "7F869481" && vars.watchers["musicTrack"].Current.ToString("X") == "F6" ) {
print("Bug Catcher " + vars.bugCounter.ToString());
vars.bugWait = "wait";
if (settings["bugCatcher2"] == true) {
print("[Autosplitter] CustomSplit: Beat Bug Catcher 2");
return true; //split
}
}}  
  
if (vars.bugCounter.ToString() == "2" && vars.bugWait.ToString() == "wait" && vars.watchers["opponentName"].Current.ToString("X") == "7F869481" && vars.watchers["musicTrack"].Current.ToString("X") == "ED" ) {  
    vars.bugWait = "go";
    vars.bugCounter =  "3" ;  
  }
  
if (vars.bugWait.ToString() == "go" && vars.bugCounter.ToString() ==  "3" ){
if (vars.watchers["opponentName"].Current.ToString("X") == "7F869481" && vars.watchers["musicTrack"].Current.ToString("X") == "F6" ) {
print("Bug Catcher " + vars.bugCounter.ToString());
vars.bugWait = "wait";
if (settings["bugCatcher3"] == true) {
print("[Autosplitter] CustomSplit: Beat Bug Catcher 3");
return true; //split
}
}}  
}

  
  
  
  


//print("bugvcounter" + vars.bugCounter.ToString());
//print("bugwait" + vars.bugWait.ToString());


//variable.ToString("X") to get hex

//print("opponentName " + vars.watchers["opponentName"].Current.ToString("X"));

//print("opponentPkmn " + vars.watchers["opponentPkmn"].Current.ToString("X"));
//print("opponentPkmn " + vars.watchers["opponentPkmn"].Current.ToString());
//print("state " + vars.watchers["state"].Current.ToString("X"));


//used to find current song
//print("musicBank   " + vars.watchers["musicBank"].Current.ToString("X"));
//print("musicTrack  " + vars.watchers["musicTrack"].Current.ToString("X"));

//print("mapIndex  " + vars.watchers["mapIndex"].Current.ToString("X"));
//print("hofPlayerShown  " + vars.watchers["hofPlayerShown"].Current.ToString("X"));

//print("mapIndex  " + vars.watchers["mapIndex"].Current.ToString("X"));







    foreach (var _split in vars.splits)
    {
        if (settings[_split.Item1])
        {
            var count = 0;
            foreach (var _condition in _split.Item2)
            {
                if (vars.watchers[_condition.Item1].Current == _condition.Item2)
                    count++;
            }

            if (count == _split.Item2.Count)
            {
                print("[Autosplitter] Split: " + _split.Item1);
                vars.splits.Remove(_split);
                return true;
            }
        }
    }
}

shutdown
{
    timer.OnStart -= vars.timer_OnStart;
}