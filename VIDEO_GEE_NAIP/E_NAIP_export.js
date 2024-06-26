var geometry = 
    /* color: #d63000 */
    /* shown: false */
    /* displayProperties: [
      {
        "type": "rectangle"
      }
    ] */
    ee.Geometry.Polygon(
        [[[-77.22714259530639, 38.83850984477243],
          [-77.22714259530639, 38.828815216642035],
          [-77.20467641259765, 38.828815216642035],
          [-77.20467641259765, 38.83850984477243]]], null, false);


// You need to create a geometry, otherwise this will not work. 

var yearBefore = '2004'
var yearAfter = '2018'

// var dataset = ee.ImageCollection('USDA/NAIP/DOQQ')
//                   .filter(ee.Filter.date('2017-01-01', '2018-12-31'));

var datasetBefore = ee.ImageCollection('USDA/NAIP/DOQQ')
                  .filter(ee.Filter.bounds(geometry))
                  .filter(ee.Filter.date(yearBefore +'-01-01', yearBefore+'-12-31'))

var datasetAfter = ee.ImageCollection('USDA/NAIP/DOQQ')
                  .filter(ee.Filter.bounds(geometry))
                  .filter(ee.Filter.date(yearAfter +'-01-01', yearAfter+'-12-31'))


// var trueColor = dataset.select(['R', 'G', 'B']);
var befImg = datasetBefore.select(['R', 'G', 'B'])
befImg = befImg.median().clip(geometry);

var aftImg = datasetAfter.select(['R', 'G', 'B'])
aftImg = aftImg.median().clip(geometry);

var trueColorVis = {
  min: 0,
  max: 255,
};

// Code from:
// https://medium.com/google-earth/histogram-matching-c7153c85066d
// Create a lookup table to make sourceHist match targetHist.
var lookup = function(befImg, aftImg) {
  // Split the histograms by column and normalize the counts.
  var sourceValues = befImg.slice(1, 0, 1).project([0])
  var sourceCounts = befImg.slice(1, 1, 2).project([0])
  sourceCounts = sourceCounts.divide(sourceCounts.get([-1]))

  var targetValues = aftImg.slice(1, 0, 1).project([0])
  var targetCounts = aftImg.slice(1, 1, 2).project([0])
  targetCounts = targetCounts.divide(targetCounts.get([-1]))

  // Find first position in target where targetCount >= srcCount[i], for each i.
  var lookup = sourceCounts.toList().map(function(n) {
    var index = targetCounts.gte(n).argmax()
    return targetValues.get(index)
  })
  return {x: sourceValues.toList(), y: lookup}
}

// Make the histogram of sourceImg match targetImg.
var histogramMatch = function(befImg, aftImg) {
  var geom = befImg.geometry()
  var args = {
    reducer: ee.Reducer.autoHistogram({maxBuckets: 256, cumulative: true}), 
    geometry: geom,
    scale: 30, // Need to specify a scale, but it doesn't matter what it is because bestEffort is true.
    maxPixels: 65536 * 4 - 1,
    bestEffort: true
  }
  
  // Only use pixels in target that have a value in source
  // (inside the footprint and unmasked).
  var source = befImg.reduceRegion(args)
  var target = aftImg.updateMask(sourceImg.mask()).reduceRegion(args)

  return ee.Image.cat(
    befImg.select(['R'])
      .interpolate(lookup(source.getArray('R'), target.getArray('R'))),
    befImg.select(['G'])
      .interpolate(lookup(source.getArray('G'), target.getArray('G'))),
    befImg.select(['B'])
      .interpolate(lookup(source.getArray('B'), target.getArray('B')))
  )
}


var result = histogramMatch(befImg,aftImg)




Map.setCenter(-77.218066, 38.83427, 15); 
Map.addLayer(aftImg, trueColorVis, yearAfter);
Map.addLayer(befImg, trueColorVis, yearBefore);
Map.addLayer(result, trueColorVis, 'Histogram Matched' + yearBefore);

Export.image.toDrive({
  image: aftImg,
  description: yearAfter,
  scale: 0.6,
  region: geometry
})

Export.image.toDrive({
  image: result,
  description: 'Histogram Matched' + yearBefore ,
  scale: 0.6,
  region: geometry
})