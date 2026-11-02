# demo video run of show - 180 seconds

bryan's voice: direct, concise, no filler, no banned ticks, plain statements. speakable sentences at ~150 wpm. total spoken words target: 380-420. music beats noted where words stop.

---

## matrix

| time | slide | what to say | on screen / live |
|------|-------|-------------|------------------|
| 0:00-0:08 | 1 - title | Cloudcroft Disc Golf. A live map and scorecard for two mountain courses in New Mexico, built from a survey I walked myself. | stay on slide 1. basket 1 photo with pines. no click yet. |
| 0:08-0:23 | 2 - read the screen | One honesty note before I click. A refreshed walkthrough is being smoke-tested, so I will narrate exactly what appears. Everything you see is the live product. | point at the pending vs live split. do not promise labels that are not visible. |
| 0:23-0:45 | 3 - enter the map | Open the site. Click into the map. Both Cloudcroft courses are here. Nine-hole Tiki putting course. Eighteen-hole Community course. Topo, satellite, trails, and aerial imagery as layers. Scorecard beside the map. No app install. No account. | live: open https://bryanchasko.com/cloudcroft-disc-golf/ then click "Open the live map" to /app/ |
| 0:45-1:12 | 4 - mountaintop, tee box 2 | This is the mountaintop moment. Tee box two is the highest pad surveyed. Sign at my feet reads par three, two forty-five, mandatory right, fence line out of bounds. Panorama was shot one metre from the averaged GPS point. View, sign, and map pin are the same field evidence. | in walk: click Mountaintop (or "Stand on the mountaintop — tee box 2" if live). drag inside pano. show pad card. |
| 1:12-1:45 | 5 - explore photos and panos | Now I explore. Everything opens from one field day. Basket photo. Kiosk. Tee signs. Each carries the GPS position where taken. Panoramas go further. Stand at Hole one tee. Both baskets. Tiki fairway. Look around as if back on the mountain. | on map: open 2-3 survey points to show field photos. in walk: step through panos A-F. keep it brisk. |
| 1:45-2:07 | 6 - survey to map pipeline | How did a walk become this map. Averaged GPS points in SW Maps. Plain-English remark at each one. Small scripts convert the backup to GeoJSON. Validate. Report gaps instead of inventing data. Sample elevation for plays-like distance. Publish. Next field day drops in without touching code. | stay on slide. point at the five-step flow: walk, convert, validate, build, publish. |
| 2:07-2:25 | 7 - AWS architecture | Underneath is one CDK stack. Amazon Location Service for maps, geocoding, geofences, routes. Two Rust Lambdas for plays-like and scorecard. DynamoDB. S3. CloudFront. Cognito guest pool gives the browser one scoped role. Graviton ARM64 for the lambdas. | stay on slide. trace the flow: visitor to Location to API to data. |
| 2:25-2:38 | 8 - open data provenance | Open data under this. One-metre USGS elevation. 2022 aerial imagery. OpenStreetMap trails. Kept the receipts for what we measured and rejected. USGS 3DEP DEM. NAIP imagery. OSM extract. Ground truth averaged phone GPS and photos. | stay on slide. point at measured/rejected split. |
| 2:38-2:55 | 9 - close | Nothing here needs a survey crew. Phone. Free field app. Open elevation and imagery. One small AWS stack. Turned a weekend walk into a map anyone can stand inside. Your course could be next. | end on URL. leave 5 seconds silence for music tail. |
| 2:55-3:00 | buffer | [music fade out] | show repo URL placeholder: `<PUBLIC_REPO_URL>` |

---

## word count breakdown

| segment | words |
|---------|-------|
| 0:00-0:08 | 23 |
| 0:08-0:23 | 28 |
| 0:23-0:45 | 40 |
| 0:45-1:12 | 48 |
| 1:12-1:45 | 44 |
| 1:45-2:07 | 50 |
| 2:07-2:25 | 38 |
| 2:25-2:38 | 34 |
| 2:38-2:55 | 39 |
| **total** | **344** |

344 words at 150 wpm = 2:18 spoken. buffer to 2:55 with music beats and natural pauses. target range 380-420 allows expansion if needed.

---

## honest limits (spoken or implied)

- Community 3 unsurveyed (basket photographed, tee awaiting field data). holes 4-18 scaffold only.
- Tiki points partially identified.
- Android AR companion is stretch goal. not scaffolded. do not promise on-tee AR.

---

## data story sources (spoken)

- USGS 3DEP 1m DEM (NM_SouthEast_2018_D19) - elevation source of record
- USGS NAIP 2022, 60cm - aerial imagery overlay
- OpenStreetMap - 46 paths + 26 footways, live Overpass extract
- Ground truth - averaged phone GPS, EXIF-geolocated photos, six 360 panos, tee-sign cross-checks
- NOAA climate normals (not spoken in main flow, available if asked)

---

## AWS pieces (spoken)

- Amazon Location Service - topo + imagery maps, place index, geofences, tracker, routes
- AWS Lambda - Rust ARM64 (Graviton), plays-like + scorecard
- Amazon DynamoDB - scorecards
- Amazon S3 - dataset + web bundle
- Amazon CloudFront - site distribution
- Amazon Cognito - guest pool, one scoped role
- AWS CDK - one TypeScript stack in us-east-1

---

## pre-record checklist

1. verify live site responds: `curl -I https://bryanchasko.com/cloudcroft-disc-golf/`
2. verify map app responds: `curl -I https://bryanchasko.com/cloudcroft-disc-golf/app/`
3. confirm walk page labels by fetching `/app/walk.html` - narrate only what renders
4. close all other browser tabs. disable notifications. set phone to do-not-disturb.
5. queue background music. start recording. hit the cold open immediately.
