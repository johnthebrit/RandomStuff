Configuration WebConfig
{
   param([string[]]$computerName="localhost") #optional parameters

   Node $computerName #zero or more node blocks
   {
      WindowsFeature WebServer #one or more resource blocks
      {
          Ensure = "Present" # To uninstall the role, set Ensure to "Absent"
          Name = "Web-Server"  
      }
   }
}