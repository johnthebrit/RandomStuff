$template="C:\Users\john\OneDrive\Courses\AZ-900\AZ900-M0-Template.pds"
$path = Split-Path $template
$templatefile = Split-Path $template -Leaf
$filenameprefix = $templatefile.Substring(0,$templatefile.IndexOf('-M0')+2)

$moduleNumber = 3
$noOfLessons = 10

foreach ($i in 1..$noOfLessons)
{
    $targetName = $filenameprefix + $moduleNumber + "-" + $i.ToString() + ".pds"
    Copy-Item $template -Destination "$path\$targetName"
}
