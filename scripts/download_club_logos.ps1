$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'
$headers = @{ 'User-Agent' = 'FC26Conquest/1.0 (local desktop app build; logo asset bundling)' }

$logos = @(
  @{ id=1;  slug='liverpool';          url='https://upload.wikimedia.org/wikipedia/en/thumb/0/0c/Liverpool_FC.svg/250px-Liverpool_FC.svg.png' },
  @{ id=2;  slug='bayern-munich';      url='https://upload.wikimedia.org/wikipedia/commons/thumb/8/8d/FC_Bayern_M%C3%BCnchen_logo_%282024%29.svg/960px-FC_Bayern_M%C3%BCnchen_logo_%282024%29.svg.png' },
  @{ id=3;  slug='real-madrid';        url='https://upload.wikimedia.org/wikipedia/en/thumb/5/56/Real_Madrid_CF.svg/330px-Real_Madrid_CF.svg.png' },
  @{ id=4;  slug='chelsea';            url='https://upload.wikimedia.org/wikipedia/en/thumb/c/cc/Chelsea_FC.svg/330px-Chelsea_FC.svg.png' },
  @{ id=5;  slug='inter';              url='https://upload.wikimedia.org/wikipedia/commons/thumb/0/05/FC_Internazionale_Milano_2021.svg/960px-FC_Internazionale_Milano_2021.svg.png' },
  @{ id=6;  slug='ajax';               url='https://upload.wikimedia.org/wikipedia/commons/0/0d/Logo_AFC_Ajax_%281928-1991%2C_2025-%29.png' },
  @{ id=7;  slug='borussia-dortmund';  url='https://upload.wikimedia.org/wikipedia/commons/thumb/6/67/Borussia_Dortmund_logo.svg/960px-Borussia_Dortmund_logo.svg.png' },
  @{ id=8;  slug='arsenal';            url='https://upload.wikimedia.org/wikipedia/en/thumb/5/53/Arsenal_FC.svg/330px-Arsenal_FC.svg.png' },
  @{ id=9;  slug='manchester-city';    url='https://upload.wikimedia.org/wikipedia/en/thumb/e/eb/Manchester_City_FC_badge.svg/330px-Manchester_City_FC_badge.svg.png' },
  @{ id=10; slug='manchester-united';  url='https://upload.wikimedia.org/wikipedia/en/thumb/7/7a/Manchester_United_FC_crest.svg/330px-Manchester_United_FC_crest.svg.png' },
  @{ id=11; slug='barcelona';          url='https://upload.wikimedia.org/wikipedia/en/thumb/4/47/FC_Barcelona_%28crest%29.svg/250px-FC_Barcelona_%28crest%29.svg.png' },
  @{ id=12; slug='atletico-madrid';    url='https://upload.wikimedia.org/wikipedia/en/thumb/f/f9/Atletico_Madrid_Logo_2024.svg/330px-Atletico_Madrid_Logo_2024.svg.png' },
  @{ id=13; slug='juventus';           url='https://upload.wikimedia.org/wikipedia/commons/thumb/e/ed/Juventus_FC_-_logo_black_%28Italy%2C_2020%29.svg/250px-Juventus_FC_-_logo_black_%28Italy%2C_2020%29.svg.png' },
  @{ id=14; slug='ac-milan';           url='https://upload.wikimedia.org/wikipedia/commons/thumb/d/d0/Logo_of_AC_Milan.svg/500px-Logo_of_AC_Milan.svg.png' },
  @{ id=15; slug='napoli';             url='https://upload.wikimedia.org/wikipedia/commons/thumb/4/4d/SSC_Napoli_2025_%28white_and_azure%29.svg/960px-SSC_Napoli_2025_%28white_and_azure%29.svg.png' },
  @{ id=16; slug='psg';                url='https://upload.wikimedia.org/wikipedia/en/thumb/a/a7/Paris_Saint-Germain_F.C..svg/330px-Paris_Saint-Germain_F.C..svg.png' },
  @{ id=17; slug='marseille';          url='https://upload.wikimedia.org/wikipedia/commons/thumb/4/4f/Olympique_de_Marseille_2026_logo.svg/330px-Olympique_de_Marseille_2026_logo.svg.png' },
  @{ id=18; slug='rb-leipzig';         url='https://upload.wikimedia.org/wikipedia/en/thumb/0/04/RB_Leipzig_2014_logo.svg/500px-RB_Leipzig_2014_logo.svg.png' },
  @{ id=19; slug='bayer-leverkusen';   url='https://upload.wikimedia.org/wikipedia/en/thumb/5/59/Bayer_04_Leverkusen_logo.svg/500px-Bayer_04_Leverkusen_logo.svg.png' },
  @{ id=20; slug='benfica';            url='https://upload.wikimedia.org/wikipedia/en/thumb/a/a2/SL_Benfica_logo.svg/330px-SL_Benfica_logo.svg.png' },
  @{ id=21; slug='porto';              url='https://upload.wikimedia.org/wikipedia/en/thumb/f/f1/FC_Porto.svg/330px-FC_Porto.svg.png' },
  @{ id=22; slug='sporting-cp';        url='https://upload.wikimedia.org/wikipedia/commons/thumb/e/e7/Sporting_Clube_de_Portugal_2026.svg/960px-Sporting_Clube_de_Portugal_2026.svg.png' },
  @{ id=23; slug='feyenoord';          url='https://upload.wikimedia.org/wikipedia/commons/thumb/f/f9/Feyenoord_logo_since_2024.svg/960px-Feyenoord_logo_since_2024.svg.png' },
  @{ id=24; slug='psv';                url='https://upload.wikimedia.org/wikipedia/en/thumb/0/05/PSV_Eindhoven.svg/500px-PSV_Eindhoven.svg.png' },
  @{ id=25; slug='galatasaray';        url='https://upload.wikimedia.org/wikipedia/commons/thumb/0/07/Galatasaray_S.K._Logo_2026_5-stars.svg/1920px-Galatasaray_S.K._Logo_2026_5-stars.svg.png' },
  @{ id=26; slug='fenerbahce';         url='https://upload.wikimedia.org/wikipedia/en/thumb/3/39/Fenerbah%C3%A7e.svg/1280px-Fenerbah%C3%A7e.svg.png' },
  @{ id=27; slug='flamengo';           url='https://upload.wikimedia.org/wikipedia/commons/thumb/9/96/Clube_de_Regatas_do_Flamengo_logo.svg/500px-Clube_de_Regatas_do_Flamengo_logo.svg.png' },
  @{ id=28; slug='palmeiras';          url='https://upload.wikimedia.org/wikipedia/commons/6/60/SE_Palmeiras_2025_crest.png' },
  @{ id=29; slug='boca-juniors';       url='https://upload.wikimedia.org/wikipedia/commons/thumb/e/e3/Boca_Juniors_logo18.svg/1280px-Boca_Juniors_logo18.svg.png' },
  @{ id=30; slug='river-plate';        url='https://upload.wikimedia.org/wikipedia/commons/thumb/4/43/Club_Atl%C3%A9tico_River_Plate_logo.svg/1280px-Club_Atl%C3%A9tico_River_Plate_logo.svg.png' },
  @{ id=31; slug='red-bull-salzburg';  url='https://upload.wikimedia.org/wikipedia/en/thumb/7/77/FC_Red_Bull_Salzburg_logo.svg/960px-FC_Red_Bull_Salzburg_logo.svg.png' },
  @{ id=32; slug='rapid-wien';         url='https://upload.wikimedia.org/wikipedia/commons/thumb/b/bf/SK_Rapid_Wien_Logo.svg/960px-SK_Rapid_Wien_Logo.svg.png' },
  @{ id=33; slug='lask';               url='https://upload.wikimedia.org/wikipedia/commons/thumb/a/a2/LASK-Logo_2023.svg/960px-LASK-Logo_2023.svg.png' },
  @{ id=35; slug='club-brugge';        url='https://upload.wikimedia.org/wikipedia/commons/9/97/Club_brugge.png' },
  @{ id=36; slug='young-boys';         url='https://upload.wikimedia.org/wikipedia/commons/c/c2/BSC_Young_Boys.svg'; ext='svg' },
  @{ id=37; slug='basel';              url='https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/FC_Basel_crest.svg/960px-FC_Basel_crest.svg.png' },
  @{ id=38; slug='celtic';             url='https://upload.wikimedia.org/wikipedia/en/thumb/7/71/Celtic_FC_crest.svg/960px-Celtic_FC_crest.svg.png' },
  @{ id=39; slug='rangers';            url='https://upload.wikimedia.org/wikipedia/en/thumb/4/43/Rangers_FC.svg/960px-Rangers_FC.svg.png' },
  @{ id=41; slug='al-nassr';           url='https://upload.wikimedia.org/wikipedia/commons/thumb/3/3f/Nassr_FC_Logo.svg/960px-Nassr_FC_Logo.svg.png' },
  @{ id=42; slug='inter-miami';        url='https://upload.wikimedia.org/wikipedia/en/thumb/5/5c/Inter_Miami_CF_logo.svg/960px-Inter_Miami_CF_logo.svg.png' },
  @{ id=34; slug='sturm-graz';         url='https://upload.wikimedia.org/wikipedia/en/9/91/SK_Sturm_Graz_logo.svg'; ext='svg' },
  @{ id=44; slug='wolfsberger-ac';     url='https://upload.wikimedia.org/wikipedia/en/c/cd/Wolfsberger_AC_logo.svg'; ext='svg' },
  @{ id=45; slug='wsg-tirol';          url='https://upload.wikimedia.org/wikipedia/en/8/85/WSG_Tirol_logo.svg'; ext='svg' }
)

$results = New-Object System.Collections.Generic.List[object]

foreach ($logo in $logos) {
  $extension = if ($logo.ContainsKey('ext')) { $logo.ext } else { 'png' }
  $dest = "assets/logos/$($logo.slug).$extension"
  $ok = $false
  $lastError = ''
  for ($attempt = 1; $attempt -le 4; $attempt++) {
    try {
      Invoke-WebRequest -Uri $logo.url -Headers $headers -OutFile $dest -TimeoutSec 30 -ErrorAction Stop
      $size = (Get-Item $dest).Length
      if ($size -gt 500) {
        $ok = $true
        break
      } else {
        $lastError = "too small ($size bytes)"
      }
    } catch {
      $lastError = $_.Exception.Message
      Start-Sleep -Seconds 3
    }
  }
  $finalSize = 0
  if (Test-Path $dest) { $finalSize = (Get-Item $dest).Length }
  $results.Add([PSCustomObject]@{ id = $logo.id; slug = $logo.slug; ok = $ok; size = $finalSize; error = $lastError })
}

$results | Format-Table -AutoSize
$failCount = ($results | Where-Object { -not $_.ok }).Count
Write-Host "DONE. Failures: $failCount"
