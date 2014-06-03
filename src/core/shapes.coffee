util = require './util'

shapes = {}


defineShape = (name, props) ->
  Shape = (args...) ->
    props.constructor.call(this, args...)
    this
  Shape.prototype.className = name
  Shape.fromJSON = props.fromJSON
  Shape.prototype.update = (ctx, bufferCtx) -> @draw(ctx, bufferCtx)

  for k of props
    if k != 'fromJSON'
      Shape.prototype[k] = props[k]

  shapes[name] = Shape
  Shape


createShape = (name, args...) ->
  new shapes[name](args...)


JSONToShape = ({className, data}) ->
  if className of shapes
    shape = shapes[className].fromJSON(data)
    if shape
      return shape
    else
      console.log 'Unreadable shape:', className, data
      return null
  else
    console.log "Unknown shape:", className, data
    return null


shapeToJSON = (shape) ->
  {className: shape.className, data: shape.toJSON()}


# this fn depends on Point, but LinePathShape depends on it, so it can't be
# moved out of this file yet.
bspline = (points, order) ->
  if not order
    return points
  return bspline(_dual(_dual(_refine(points))), order - 1)

_refine = (points) ->
  points = [points[0]].concat(points).concat(util.last(points))
  refined = []

  index = 0
  for point in points
    refined[index * 2] = point
    refined[index * 2 + 1] = _mid point, points[index + 1] if points[index + 1]
    index += 1

  return refined

_dual = (points) ->
  dualed = []

  index = 0
  for point in points
    dualed[index] = _mid point, points[index + 1] if points[index + 1]
    index += 1

  return dualed

_mid = (a, b) ->
  createShape('Point', {
    x: a.x + ((b.x - a.x) / 2),
    y: a.y + ((b.y - a.y) / 2),
    size: a.size + ((b.size - a.size) / 2),
    color: a.color
  })


defineShape 'Image',
  # TODO: allow resizing/filling
  constructor: (args={}) ->
    @x = args.x or 0
    @y = args.y or 0
    @image = args.image or null
  draw: (ctx, retryCallback) ->
    if @image.width
      ctx.drawImage(@image, @x, @y)
    else
      @image.onload = retryCallback
  toJSON: -> {@x, @y, imageSrc: @image.src}
  fromJSON: (data) ->
    img = new Image()
    img.src = data.imageSrc
    createShape('Image', {x: data.x, x: data.y, image: img})


defineShape 'Rectangle',
  constructor: (args={}) ->
    @x = args.x or 0
    @y = args.y or 0
    @width = args.width or 0
    @height = args.height or 0
    @strokeWidth = args.strokeWidth or 1
    @strokeColor = args.strokeColor or 'black'
    @fillColor = args.fillColor or 'transparent'

  draw: (ctx) ->
    ctx.fillStyle = @fillColor
    ctx.fillRect(@x, @y, @width, @height)
    ctx.lineWidth = @strokeWidth
    ctx.strokeStyle = @strokeColor
    ctx.strokeRect(@x, @y, @width, @height)

  toJSON: -> {@x, @y, @width, @height, @strokeWidth, @strokeColor, @fillColor}
  fromJSON: (data) -> createShape('Rectangle', data)


defineShape 'Line',
  constructor: (args={}) ->
    @x1 = args.x1 or 0
    @y1 = args.y1 or 0
    @x2 = args.x2 or 0
    @y2 = args.y2 or 0
    @strokeWidth = args.strokeWidth or 1
    @color = args.color or 'black'

  draw: (ctx) ->
    ctx.lineWidth = @strokeWidth
    ctx.strokeStyle = @color
    ctx.lineCap = 'round'
    ctx.beginPath()
    ctx.moveTo(@x1, @y1)
    ctx.lineTo(@x2, @y2)
    ctx.stroke()

  toJSON: -> {@x1, @y1, @x2, @y2, @strokeWidth, @color}
  fromJSON: (data) -> createShape('Line', data)


linePathFuncs = 
  constructor: (args={}) ->
    points = args.points or []
    @order = args.order or 3
    @tailSize = args.tailSize or 3

    # The number of smoothed points generated for each point added
    @segmentSize = Math.pow(2, @order)

    # The number of points used to calculate the bspline to the newest point
    @sampleSize = @tailSize + 1

    @points = []
    for point in points
      @addPoint(point)

  toJSON: ->
    # TODO: make point storage more efficient
    {@order, @tailSize, points: (shapeToJSON(p) for p in @points)}

  fromJSON: (data) ->
    points = (JSONToShape(pointData) for pointData in data.points)
    return null unless points[0]
    createShape(
      'LinePath', {points, order: data.order, tailSize: data.tailSize})

  draw: (ctx) ->
    @drawPoints(ctx, @smoothedPoints)

  update: (ctx, bufferCtx) ->
    @drawPoints(ctx, if @tail then @tail else @smoothedPoints)

    if @tail
      segmentStart = @smoothedPoints.length - @segmentSize * @tailSize
      drawStart = if segmentStart < @segmentSize * 2 then 0 else segmentStart
      drawEnd = segmentStart + @segmentSize + 1
      @drawPoints(bufferCtx,@smoothedPoints.slice(drawStart, drawEnd))

  addPoint: (point) ->
    @points.push(point)

    if not @smoothedPoints or @points.length < @sampleSize
      @smoothedPoints = bspline(@points, @order)
    else
      @tail = util.last(
        bspline(util.last(@points, @sampleSize), @order),
                   @segmentSize * @tailSize)

      # Remove the last @tailSize - 1 segments from @smoothedPoints
      # then concat the tail. This is done because smoothed points
      # close to the end of the path will change as new points are
      # added.
      @smoothedPoints = @smoothedPoints.slice(
        0, @smoothedPoints.length - @segmentSize * (@tailSize - 1)
      ).concat(@tail)

  drawPoints: (ctx, points) ->
    return unless points.length

    ctx.lineCap = 'round'

    ctx.strokeStyle = points[0].color
    ctx.lineWidth = points[0].size

    ctx.beginPath()
    ctx.moveTo(points[0].x, points[0].y)

    for point in points.slice(1)
        ctx.lineTo(point.x, point.y)

    ctx.stroke()


LinePath = defineShape 'LinePath', linePathFuncs


defineShape 'ErasedLinePath',
  constructor: linePathFuncs.constructor
  toJSON: linePathFuncs.toJSON
  addPoint: linePathFuncs.addPoint
  drawPoints: linePathFuncs.drawPoints

  draw: (ctx) ->
    ctx.save()
    ctx.globalCompositeOperation = "destination-out"
    linePathFuncs.draw.call(this, ctx)
    ctx.restore()

  update: (ctx, bufferCtx) ->
    ctx.save()
    ctx.globalCompositeOperation = "destination-out"
    bufferCtx.save()
    bufferCtx.globalCompositeOperation = "destination-out"

    linePathFuncs.update.call(this, ctx, bufferCtx)

    ctx.restore()
    bufferCtx.restore()

  # same as LinePah
  fromJSON: (data) ->
    points = (JSONToShape(pointData) for pointData in data.points)
    return null unless points[0]
    createShape(
      'ErasedLinePath', {points, order: data.order, tailSize: data.tailSize})


defineShape 'Point',
  constructor: (args={}) ->
    @x = args.x or 0
    @y = args.y or 0
    @size = args.size or 0
    @color = args.color or ''
  lastPoint: -> this
  draw: (ctx) -> throw "not implemented"
  toJSON: -> {@x, @y, @size, @color}
  fromJSON: (data) -> createShape('Point', data)


defineShape 'Text',
  constructor: (args={}) ->
    @x = args.x or 0
    @y = args.y or 0
    @text = args.text or ''
    @color = args.color or 'black'
    @font  = args.font or '18px sans-serif'
  draw: (ctx) -> 
    ctx.font  = @font
    ctx.fillStyle = @color
    ctx.fillText(@text, @x, @y)
  toJSON: -> {@x, @y, @text, @color, @font}
  fromJSON: (data) -> createShape('Text', data)


module.exports = {defineShape, createShape, JSONToShape, shapeToJSON}