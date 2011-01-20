#include FcnLib.ahk

debug("log grey line", "starting nightly scripts")

RunAhkAndBabysit("MorningStatus-GatherData.ahk")
SleepMinutes(1)
RunAhkAndBabysit("CopyVimSettings.ahk")
SleepMinutes(1)
RunAhkAndBabysit("RestartDropbox.ahk")
SleepMinutes(1)
RunAhkAndBabysit("UnitTests.ahk")
SleepMinutes(10)
if (A_ComputerName="BAUSTIAN-09PC")
{
   RunAhk("SaveChromeBookmarks.ahk")
   SleepMinutes(1)
   RunAhk("CreateDropboxBackup.ahk")
   SleepMinutes(10)
   RunAhk("PushToGit.ahk")
   SleepMinutes(3)
}
else if (A_ComputerName="PHOSPHORUS")
{
   RunAhkAndBabysit("RestartFirefox.ahk")
   SleepMinutes(1)
   RunAhkAndBabysit("UpdatePidginImStatus.ahk")
   SleepMinutes(1)
   RunAhkAndBabysit("UsaaGetAccountBalances.ahk")
   SleepMinutes(5)
   ;RunAhkAndBabysit("UsaaGetAccountCsvs.ahk")
   SleepMinutes(5)
   RunAhkAndBabysit("MintGetAccountCsvs.ahk")
   SleepMinutes(5)
   RunAhkAndBabysit("CreateFinancialPieChart.ahk")
   SleepMinutes(15)
}
else if (A_ComputerName="PHOSPHORUSVM")
{
   RunAhkAndBabysit("DeleteDropboxCruft")
   SleepMinutes(30)
   ;RunAhkAndBabysit("UsaaGetAccountBalances.ahk")
   SleepMinutes(5)
   ;RunAhkAndBabysit("UsaaGetAccountCsvs.ahk")
   SleepMinutes(5)
}

RunAhkAndBabysit("StartIdleAhks.ahk")
SleepMinutes(1)

debug("log grey line", "finished nightly scripts")
