console.log "loading graph.js.coffee"


# draw the rating results curve
# convert the rating results into a set of coordinates and draw a curve
# find the correct canvas
#

class Graph
  draw_rating_results: (ctx, vote_counts) ->

    lineargradient = ctx.createLinearGradient(20,0,270,0);
    lineargradient.addColorStop(0,'#FF0000');
    lineargradient.addColorStop(0.5,'#FFFF00');
    lineargradient.addColorStop(1,'#00FF00');
    ctx.fillStyle = lineargradient;
    ctx.strokeStyle = lineargradient;
    ctx.lineWidth = 3

    width = 350
    height = 150
    int_width = width/(vote_counts.length - 1)
    vote_scaler = (height - 10) / (Math.max vote_counts...)
    vote_coords = []
    for vote, i in vote_counts
      vote_coords.push i * int_width
      vote_coords.push height - vote * vote_scaler


    #vote_counts = [10, 2, 20, 5, 30, 8, 40, 9, 50, 17, 60, 28, 70, 42, 80, 49, 90, 16, 100, 29];
    this.draw_curve(ctx, vote_coords,.5, true, 10, false);


  #	Uses an array of points (x,y) to draw a smooth curve (cardinal spline).
  #	There is no use of control points, and the curve is drawn through each
  #	point.
  #
  #	USAGE:
  #		drawCurve(context, points, tension, isClosed, numberOfSegments, showPoints)
  #
  #		drawCurve(context, array)
  #		drawCurve(content, array, float)
  #		drawCurve(content, array, float, boolean)
  #		drawCurve(content, array, float, boolean, integer)
  #		drawCurve(content, array, float, boolean, integer, boolean)
  #
  #	context				= 2d context from canvas element
  #	points				= array of float or integers arranged as x/y couples. Minimum 2 points.
  #	tension				= [0, 1], 0 = no smoothing, 0.5 = smooth (default), 1 = very smoothed
  #	isClosed			= draw a closed curve if true (default is false)
  #	numberOfSegments	= resolution of the smoothed curve. Higer number -> smoother (default 16)
  #	showPoints			= true if you want to see the input points' location
  #
  #	NOTE: array must contain a minimum set of two points.

  draw_curve: (ctx, ptsa, tension, isClosed, numOfSegments, showPoints = false) ->
    ctx.beginPath();

    symmetrical = true
    if symmetrical
      set_of_coords = this.get_curve_coords_one_side(ptsa, tension, isClosed, numOfSegments)

      pos_coords = []
      for coord, index in set_of_coords
        pos_coords.push( if index % 2 is 0 then coord else coord/2)

      half_height = ctx.canvas.height
      neg_coords = []
      for coord, index in set_of_coords
        neg_coords.push( if index % 2 is 0 then coord else half_height - coord/2)

      reverse_neg_coords = []
      for i in [neg_coords.length-2...-2] by -2
        reverse_neg_coords.push neg_coords[i]
        reverse_neg_coords.push neg_coords[i+1]
      
      this.draw_lines_symmetrical_and_close(ctx,pos_coords,reverse_neg_coords)

    else
      set_of_coords = this.get_curve_coords_one_side(ptsa, tension, isClosed, numOfSegments)
      this.draw_lines_one_side_and_close(ctx,set_of_coords)
      if showPoints
        ctx.stroke()
        ctx.beginPath()
        for pts_item, index in ptsa when index % 2 is 0
          ctx.rect(ptsa[index] - 2, ptsa[index+1] - 2, 4, 4)
      ctx.stroke()



  #	Draws an array of points (x/ couples).
  #
  #	USAGE:
  #		drawLines(context, points)
  #
  #		drawLines(context, array)
  #
  #	context	= 2d context from canvas element
  #	points	= array of float or integers arranged as
  #			  x1,y1,x2,y1,...,xn,yn. Minimum 2 points.
  #
  #	NOTE: array must contain a minimum set of two points.

  draw_lines_one_side_and_close: (ctx, pts) ->
    ctx.moveTo(0,ctx.canvas.height)
    ctx.lineTo(pts[0], pts[1])
    #ctx.moveTo(0, 0)
    for pts_item, index in pts when index > 1 and index % 2 is 0
      #console.log "lineTo x: "  + pts[index] + ", y: " + pts[index+1]
      ctx.lineTo(pts[index], pts[index+1]);
    ctx.lineTo(ctx.canvas.width,ctx.canvas.height)
    ctx.lineTo(0,ctx.canvas.height)
    ctx.fill()

  draw_lines_symmetrical_and_close: (ctx, pos_coords, neg_coords) ->
    ctx.moveTo(pos_coords[0], pos_coords[1])
    for pts_item, index in pos_coords when index > 1 and index % 2 is 0
      #console.log "lineTo x: "  + pts[index] + ", y: " + pts[index+1]
      ctx.lineTo(pos_coords[index], pos_coords[index+1]);

    ctx.lineTo(neg_coords[0], neg_coords[1])

    for pts_item, index in neg_coords when index > 1 and index % 2 is 0
      #console.log "lineTo x: "  + pts[index] + ", y: " + pts[index+1]
      ctx.lineTo(neg_coords[index], neg_coords[index+1]);

    ctx.lineTo(pos_coords[0], pos_coords[1])

    ctx.fill()

  get_curve_coords_one_side: (ptsa, tension = 0.5, isClosed = false, numOfSegments = 16) ->
    # _pts = [], res = [],	# clone array and result
    # x, y,					# our x,y coords
    # t1x, t2x, t1y, t2y,		# tension vectors
    # c1, c2, c3, c4,			# cardinal points
    # st, st2, st3, st23, st32,	# steps
    # l, t, i;				# steps based on num. of segments
    res = []
    # clone array so we don't change the original
    _pts = ptsa.concat();


    #	The algorithm require a previous and next point to the actual point array.
    #	Check if we will draw closed or open curve.
    #	If closed, copy end points to beginning and first points to end
    #	If open, duplicate first points to befinning, end points to end

    #if isClosed
    #  _pts.unshift(ptsa[ptsa.length - 1])
    #  _pts.unshift(ptsa[ptsa.length - 2])
    #  _pts.unshift(ptsa[ptsa.length - 1])
    #  _pts.unshift(ptsa[ptsa.length - 2])
    #  _pts.push(ptsa[0])
    #  _pts.push(ptsa[1])
    #else
    _pts.unshift(ptsa[1])   # copy 1. point and insert at beginning
    _pts.unshift(ptsa[0])
    _pts.push(ptsa[ptsa.length - 2]) # copy last point and append
    _pts.push(ptsa[ptsa.length - 1])


    # Calculations:
    # 1. loop goes through point array
    # 2. loop goes through each segment between the two points
    #l = (_pts.length - 4);
    for i in [2...(_pts.length-4)] by 2
      #console.log "i: #{i}"
      for t in [0..numOfSegments] 
        #console.log "t: #{t}"

        # calc tension vectors
        t1x = (_pts[i+2] - _pts[i-2]) * tension;
        t2x = (_pts[i+4] - _pts[i]) * tension;

        t1y = (_pts[i+3] - _pts[i-1]) * tension;
        t2y = (_pts[i+5] - _pts[i+1]) * tension;

        # pre-calc step
        st = t / numOfSegments;
        st2 = st * st;
        st3 = st2 * st;
        st23 = st3 * 2;
        st32 = st2 * 3;

        # calc cardinals
        c1 = st23 - st32 + 1;
        c2 = -(st23) + st32;
        c3 = st3 - 2 * st2 + st;
        c4 = st3 - st2;

        # calc x and y cords with common control vectors
        x = c1 * _pts[i]	+ c2 * _pts[i+2] + c3 * t1x + c4 * t2x;
        y = c1 * _pts[i+1]	+ c2 * _pts[i+3] + c3 * t1y + c4 * t2y;

        #store points in array
        res.push(x)
        res.push(y)
    return res

window.Graph = Graph