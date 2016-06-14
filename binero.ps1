$bineroCode = '07d03c5821503c0b3e5b2f147146270c25503c5823502a1771543a0c715d249c3d452f58355c2958275c2f5833d02a1d71412b1434532116715a2d10715063083e463a583059221971512f1f30476e1171432b1b3a5420567178ab16355429587c153a1723462a19361526192315381171c33e0834416e15345922193f1525143e5625193f157e406b057e587c157c4a6b057e5471533c1d3554291923157e406b057e587c157f416b057e583e5626583dc33c1c3052625822c3201c30526e0b30583a583950221f35542958600574486115635860007448611b44'

# S�.. f�rst beh�ver vi n�gra praktiska funktioner.

# konvertera hex till bin, f�r att kunna bruteforcea l�senordet.
$BINero = for ($i = 0; $i -lt $bineroCode.Length - 1 ; $i = $i + 2)
{
    [System.Convert]::toint16(($bineroCode.Substring($i, 2)),16)
}

# Funktion f�r att generera l�senord, 4 tecken, minst 1 gemen, minst 1 versal, minst 1 siffra.
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

# Och h�r utf�rs sj�lva bruteforce testet.
# Jag lade till parametrar f�r att manuellt kunna testa ett specifikt l�senord,
# En specifik str�ng (f�r att kunna testa ert exempel)
# och f�r enkelhets skull endast visa tecken i ASCII standard tabellen (det genererar betydligt f�rre d�liga tecken) med hj�lp av swede flaggan
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

# Jag loopade igenom mitt bruteforcescript, och l�mnar endast tillbaks resultatet om det inneh�ler ord som matchar
# n�got av dom fem vanligaste orden i svenska spr�ket.
# (och, att, det, som, en) med mellanrum f�re och efter ordet.
do {
    $a = BruteForce
    IF (($a -like "* och *") -or ($a -like "* att *")-or ($a -like "* det *")-or ($a -like "* som *")-or ($a -like "* en *"))
    {
        Write-Host $a
    }
}
While ($true)

# Efter c.a 5 minuter s� ger scriptet tillbaks f�ljande str�ng.
#
#@{pass=Q5nX; string=VRpeRSonAL sITteRreDO aTT hJlpAdiGviAbDE tELefON oCH ePosTalLA dAGarI vECkaN MNdaG- TOrsDAg HAr VI P
#PetMelLAn KLocKAn :0- :0 fREdaGAr :0- :0ocHlRDagsNDagSamTheLGdaG100 150.*}

# s� vi provk�r hela str�ngen, alla tecken med det hittade l�senordet
BruteForce -PassToTest Q5nX -Swede |fl

# Och f�r tillbaks f�ljande 
#
# pass   : Q5nX
# string : V�R peRSonAL sITteR reDO aTT hJ�lpA diG viA b�DE tELefON oCH ePosT alLA dAGar I vECkaN M�NdaG - TOrsDAg HAr
#          VI �PPet MelLAn KLocKAn :0 - :0 fREdaGAr :0 - :0 ocH l�RDag s�NDag SamT heLGdaG 100  150.*

# Inte riktigt r�tt, men n�ra.
# Genom att titta vilken del av l�senordet (tredje och fj�rde tecknet, nX) som inte st�mmer kan vi g� vidare 

'ABCDEFGHIJKLMNOPQRSTUVWXYZ' -split '' | % { BruteForce -PassToTest "Q5$($_)X" -Swede }
'abcdefghijklmnopqrstuvwxyz' -split '' | % { BruteForce -PassToTest "Q5$($_)X" -Swede }
0..9 | % { BruteForce -PassToTest "Q5$($_)X" -Swede }

# i resultatet av dessa �r 'Q5NX' ett steg n�rmare. endast sista tecknet kvar, s� vi k�r samma ska igen, med testet p� sista plats

'ABCDEFGHIJKLMNOPQRSTUVWXYZ' -split '' |% { BruteForce -PassToTest "Q5N$($_)" -Swede }
'abcdefghijklmnopqrstuvwxyz' -split '' |% { BruteForce -PassToTest "Q5N$($_)" -Swede }
0..9 | % { BruteForce -PassToTest "Q5N$($_)" -Swede }

# Och h�r f�r vi fram resultatet Q5Nx

BruteForce -PassToTest Q5Nx -Swede | fl
<#
pass   : Q5Nx
string : V�r personal sitter redo att hj�lpa dig via b�de telefon och e-post alla dagar i veckan. M�ndag - torsdag har
         vi �ppet mellan klockan 08:00 - 22:00, fredagar 08:00 - 19:00 och l�rdag, s�ndag samt helgdag 10:00 - 15:00.
#>
