$bineroCode = '07d03c5821503c0b3e5b2f147146270c25503c5823502a1771543a0c715d249c3d452f58355c2958275c2f5833d02a1d71412b1434532116715a2d10715063083e463a583059221971512f1f30476e1171432b1b3a5420567178ab16355429587c153a1723462a19361526192315381171c33e0834416e15345922193f1525143e5625193f157e406b057e587c157c4a6b057e5471533c1d3554291923157e406b057e587c157f416b057e583e5626583dc33c1c3052625822c3201c30526e0b30583a583950221f35542958600574486115635860007448611b44'

# Så.. först behöver vi några praktiska funktioner.

# konvertera hex till bin, för att kunna bruteforcea lösenordet.
$BINero = for ($i = 0; $i -lt $bineroCode.Length - 1 ; $i = $i + 2)
{
    [System.Convert]::toint16(($bineroCode.Substring($i, 2)),16)
}

# Funktion för att generera lösenord, 4 tecken, minst 1 gemen, minst 1 versal, minst 1 siffra.
function generate-password
{
    $digits = 48..57
    $letters = 65..90 + 97..122
    do
    {
        $Pass = get-random -count 4 -InputObject ($digits + $letters) | ForEach-Object -begin { $aa = $null } -process {$aa += [char]$_} -end {$aa}
    }
    until (($Pass -match "\d") -and ($Pass -cmatch "[a-z]") -and ($Pass -cmatch "[A-Z]"))
    
    return $pass
}

# Och här utförs själva bruteforce testet.
# Jag lade till parametrar för att manuellt kunna testa ett specifikt lösenord,
# En specifik sträng (för att kunna testa ert exempel)
# och för enkelhets skull endast visa tecken i ASCII standard tabellen (det genererar betydligt färre dåliga tecken) med hjälp av swede flaggan
Function BruteForce
{
param(
[String]$PassToTest = (generate-password),
$StringToTest = $BINero,
[switch]$Swede
)
$i = 0


$test = New-Object -TypeName psobject -Property @{'pass' = $PassToTest}

$XORString = -join (  $StringToTest | ForEach-Object {
    $Xor = $PassToTest[$i]
    [int]$Val = [int]$_ -bxor $Xor
    IF ($Swede)
    {
        [char][int]$val
    }
    ELSE
    { 
        IF (($Val -ge 32) -and ($Val -le 126))
        {
            [char][int]$val
        }
    }

    $i++
    IF ($i -gt $PassToTest.Length - 1)
    {
        $i = 0
    }
    
    } )

$test | Add-Member -MemberType NoteProperty -Name 'string' -Value $XORString

return $test
}

# Jag loopade igenom mitt bruteforcescript, och lämnar endast tillbaks resultatet om det innehåler ord som matchar
# något av dom fem vanligaste orden i svenska språket.
# (och, att, det, som, en) med mellanrum före och efter ordet.
do {
    $a = BruteForce
    IF (($a -like "* och *") -or ($a -like "* att *")-or ($a -like "* det *")-or ($a -like "* som *")-or ($a -like "* en *"))
    {
        Write-Host $a
    }
}
While ($true)

# Efter c.a 5 minuter så ger scriptet tillbaks följande sträng.
#
#@{pass=Q5nX; string=VRpeRSonAL sITteRreDO aTT hJlpAdiGviAbDE tELefON oCH ePosTalLA dAGarI vECkaN MNdaG- TOrsDAg HAr VI P
#PetMelLAn KLocKAn :0- :0 fREdaGAr :0- :0ocHlRDagsNDagSamTheLGdaG100 150.*}

# så vi provkör hela strängen, alla tecken med det hittade lösenordet
BruteForce -PassToTest Q5nX -Swede |fl

# Och får tillbaks följande 
#
# pass   : Q5nX
# string : VåR peRSonAL sITteR reDO aTT hJÄlpA diG viA båDE tELefON oCH ePosT alLA dAGar I vECkaN MÅNdaG - TOrsDAg HAr
#          VI öPPet MelLAn KLocKAn :0 - :0 fREdaGAr :0 - :0 ocH löRDag söNDag SamT heLGdaG 100  150.*

# Inte riktigt rätt, men nära.
# Genom att titta vilken del av lösenordet (tredje och fjärde tecknet, nX) som inte stämmer kan vi gå vidare 

'ABCDEFGHIJKLMNOPQRSTUVWXYZ' -split '' | % { BruteForce -PassToTest "Q5$($_)X" -Swede }
'abcdefghijklmnopqrstuvwxyz' -split '' | % { BruteForce -PassToTest "Q5$($_)X" -Swede }
0..9 | % { BruteForce -PassToTest "Q5$($_)X" -Swede }

# i resultatet av dessa är 'Q5NX' ett steg närmare. endast sista tecknet kvar, så vi kör samma ska igen, med testet på sista plats

'ABCDEFGHIJKLMNOPQRSTUVWXYZ' -split '' |% { BruteForce -PassToTest "Q5N$($_)" -Swede }
'abcdefghijklmnopqrstuvwxyz' -split '' |% { BruteForce -PassToTest "Q5N$($_)" -Swede }
0..9 | % { BruteForce -PassToTest "Q5N$($_)" -Swede }

# Och här får vi fram resultatet Q5Nx

BruteForce -PassToTest Q5Nx -Swede | fl
<#
pass   : Q5Nx
string : Vår personal sitter redo att hjälpa dig via både telefon och e-post alla dagar i veckan. Måndag - torsdag har
         vi öppet mellan klockan 08:00 - 22:00, fredagar 08:00 - 19:00 och lördag, söndag samt helgdag 10:00 - 15:00.
#>
