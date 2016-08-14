# Nim module for parsing GPX (GPS Exchange format) files.
# Currently it only supports GPX 1.1 (no support for GPX 1.0).

# Written by Adam Chesak.
# Released under the MIT open source license.


import xmlparser
import xmltree
import streams
import strutils


type
    GPX* = object
        version* : string
        creator* : string
        metadata* : GPXMetadata
        waypoints* : seq[GPXWaypoint]
        routes* : seq[GPXRoute]
        tracks* : seq[GPXTrack]
        extensions* : XmlNode
     
    GPXMetadata* = object
        name* : string
        desc* : string
        author* : GPXAuthor
        copyright* : GPXCopyright
        link* : seq[GPXLink]
        time* : string
        keywords* : string
        bounds* : GPXBounds
        extensions* : XmlNode
    
    GPXAuthor* = object
        name* : string
        email* : GPXEmail
        link* : GPXLink
    
    GPXEmail* = object
        id* : string
        domain* : string
    
    GPXLink* = object
        href* : string
        text* : string
        linkType* : string
    
    GPXCopyright* = object
        author* : string
        year* : string
        license* : string
    
    GPXBounds* = object
        minlat* : float
        minlon* : float
        maxlat* : float
        maxlon* : float
    
    GPXWaypoint* = object
        lat* : float
        lon* : float
        ele* : float
        time* : string
        magvar* : float
        geoidheight* : float
        name* : string
        cmt* : string
        desc* : string
        src* : string
        link* : seq[GPXLink]
        sym* : string
        waypointType* : string
        fix* : string
        sat* : int
        hdop* : float
        vdop* : float
        pdop* : float
        ageofdgpsdata* : float
        dgpsid* : int
        extensions* : XmlNode
    
    GPXRoute* = object
        name* : string
        cmt* : string
        desc* : string
        src* : string
        link* : seq[GPXLink]
        number* : int
        routeType* : string
        extensions* : XmlNode
        rtept* : seq[GPXWaypoint]
    
    GPXTrack* = object
        name* : string
        cmt* : string
        desc* : string
        src* : string
        link* : seq[GPXLink]
        number* : int
        trackType* : string
        extensions* : XmlNode
        trkseg* : seq[GPXTrackSegment]
    
    GPXTrackSegment* = object
        trkpt* : seq[GPXWaypoint]
        extensions* : XmlNode
    
    GPXError* = object of Exception


proc parseGPXMetadata(metaxml : XmlNode): GPXMetadata
proc parseGPXAuthor(authxml : XmlNode): GPXAuthor
proc parseGPXEmail(emailxml : XmlNode): GPXEmail
proc parseGPXLink(linkxml : XmlNode): GPXLink
proc parseGPXCopyright(copyxml : XmlNode): GPXCopyright
proc parseGPXBounds(boundxml : XmlNode): GPXBounds
proc parseGPXWaypoint(wayxml : XmlNode): GPXWaypoint
proc parseGPXRoute(routexml : XmlNode): GPXRoute
proc parseGPXTrack(trackxml : XmlNode): GPXTrack
proc parseGPXTrackSegment(segxml : XmlNode): GPXTrackSegment


proc parseGPXMetadata(metaxml : XmlNode): GPXMetadata = 
    ## Internal proc. Parses the XML into a ``GPXMetadata`` object.
    
    var metadata : GPXMetadata = GPXMetadata(link: @[])
    
    if metaxml.child("name") != nil:
        metadata.name = metaxml.child("name").innerText
        
    if metaxml.child("desc") != nil:
        metadata.desc = metaxml.child("desc").innerText
        
    if metaxml.child("author") != nil:
        metadata.author = parseGPXAuthor(metaxml.child("author"))
    
    if metaxml.child("copyright") != nil:
        metadata.copyright = parseGPXCopyright(metaxml.child("copyright"))
    
    for link in metaxml.findAll("link"):
        metadata.link.add(parseGPXLink(link))
    
    if metaxml.child("time") != nil:
        metadata.time = metaxml.child("time").innerText
    
    if metaxml.child("keywords") != nil:
        metadata.keywords = metaxml.child("keywords").innerText
    
    if metaxml.child("bounds") != nil:
        metadata.bounds = parseGPXBounds(metaxml.child("bounds"))
    
    if metaxml.child("extensions") != nil:
        metadata.extensions = metaxml.child("extensions")
    
    return metadata


proc parseGPXAuthor(authxml : XmlNode): GPXAuthor = 
    ## Internal proc. Parses the XML into a ``GPXAuthor`` object.
    
    var author : GPXAuthor = GPXAuthor()
    
    if authxml.child("name") != nil:
        author.name = authxml.child("name").innerText
    
    if authxml.child("email") != nil:
        author.email = parseGPXEmail(authxml.child("email"))
    
    if authxml.child("link") != nil:
        author.link = parseGPXLink(authxml.child("link"))
    
    return author


proc parseGPXEmail(emailxml : XmlNode): GPXEmail =
    ## Internal proc. Parses the XML into a ``GPXEmail`` object.
    
    var email : GPXEmail = GPXEmail()
    
    email.id = emailxml.attr("id")
    email.domain = emailxml.attr("domain")
    
    return email


proc parseGPXLink(linkxml : XmlNode): GPXLink = 
    ## Internal proc. Parses the XML into a ``GPXLink`` object.
    
    var link : GPXLink = GPXLink()
    
    link.href = linkxml.attr("href")
    
    if linkxml.child("text") != nil:
        link.text = linkxml.child("text").innerText
    
    if linkxml.child("type") != nil:
        link.linkType = linkxml.child("type").innerText
    
    return link


proc parseGPXCopyright(copyxml : XmlNode): GPXCopyright = 
    ## Internal proc. Parses the XML into a ``GPXCopyright`` object.
    
    var copyright : GPXCopyright = GPXCopyright()
    
    copyright.author = copyxml.attr("author")
    
    if copyxml.child("year") != nil:
        copyright.year = copyxml.child("year").innerText
    
    if copyxml.child("license") != nil:
        copyright.license = copyxml.child("license").innerText
    
    return copyright


proc parseGPXBounds(boundxml : XmlNode): GPXBounds = 
    ## Internal proc. Parses the XML into a ``GPXBounds`` object.
    
    var bounds : GPXBounds = GPXBounds()
    
    bounds.minlat = parseFloat(boundxml.attr("minlat"))
    bounds.minlon = parseFloat(boundxml.attr("minlon"))
    bounds.maxlat = parseFloat(boundxml.attr("maxlat"))
    bounds.maxlon = parseFloat(boundxml.attr("maxlon"))
    
    return bounds


proc parseGPXWaypoint(wayxml : XmlNode): GPXWaypoint =
    ## Internal proc. Parses the XML into a ``GPXWaypoint`` object.
    
    var waypoint : GPXWaypoint = GPXWaypoint(link: @[])
    
    waypoint.lat = parseFloat(wayxml.attr("lat"))
    waypoint.lon = parseFloat(wayxml.attr("lon"))
    
    if wayxml.child("ele") != nil:
        waypoint.ele = parseFloat(wayxml.child("ele").innerText)
    
    if wayxml.child("time") != nil:
        waypoint.time = wayxml.child("time").innerText
    
    if wayxml.child("magvar") != nil:
        waypoint.magvar = parseFloat(wayxml.child("magvar").innerText)
    
    if wayxml.child("geoidheight") != nil:
        waypoint.geoidheight = parseFloat(wayxml.child("geoidheight").innerText)
    
    if wayxml.child("name") != nil:
        waypoint.name = wayxml.child("name").innerText
    
    if wayxml.child("cmt") != nil:
        waypoint.cmt = wayxml.child("cmt").innerText
    
    if wayxml.child("desc") != nil:
        waypoint.desc = wayxml.child("desc").innerText
    
    if wayxml.child("src") != nil:
        waypoint.src = wayxml.child("src").innerText
    
    for link in wayxml.findAll("link"):
        waypoint.link.add(parseGPXLink(link))
    
    if wayxml.child("sym") != nil:
        waypoint.sym = wayxml.child("sym").innerText
    
    if wayxml.child("type") != nil:
        waypoint.waypointType = wayxml.child("type").innerText
    
    if wayxml.child("fix") != nil:
        waypoint.fix = wayxml.child("fix").innerText
    
    if wayxml.child("sat") != nil:
        waypoint.sat = parseInt(wayxml.child("sat").innerText)
    
    if wayxml.child("hdop") != nil:
        waypoint.hdop = parseFloat(wayxml.child("hdop").innerText)
    
    if wayxml.child("vdop") != nil:
        waypoint.vdop = parseFloat(wayxml.child("vdop").innerText)
    
    if wayxml.child("pdop") != nil:
        waypoint.pdop = parseFloat(wayxml.child("pdop").innerText)
    
    if wayxml.child("ageofdgpsdata") != nil:
        waypoint.ageofdgpsdata = parseFloat(wayxml.child("ageofdgpsdata").innerText)
    
    if wayxml.child("dgpsid") != nil:
        waypoint.dgpsid = parseInt(wayxml.child("dgpsid").innerText)
    
    if wayxml.child("extensions") != nil:
        waypoint.extensions = wayxml.child("extensions")
    
    return waypoint


proc parseGPXRoute(routexml : XmlNode): GPXRoute = 
    ## Internal proc. Parses the XML into a ``GPXRoute`` object.
    
    var route : GPXRoute = GPXRoute(link: @[], rtept: @[])
    
    if routexml.child("name") != nil:
        route.name = routexml.child("name").innerText
    
    if routexml.child("cmt") != nil:
        route.cmt = routexml.child("cmt").innerText
    
    if routexml.child("desc") != nil:
        route.desc = routexml.child("desc").innerText
    
    if routexml.child("src") != nil:
        route.src = routexml.child("src").innerText
    
    for link in routexml.findAll("link"):
        route.link.add(parseGPXLink(link))
    
    if routexml.child("number") != nil:
        route.number = parseInt(routexml.child("number").innerText)
    
    if routexml.child("type") != nil:
        route.routeType = routexml.child("type").innerText
    
    if routexml.child("extensions") != nil:
        route.extensions = routexml.child("extensions")
    
    for waypoint in routexml.findAll("rtept"):
        route.rtept.add(parseGPXWaypoint(waypoint))
    
    return route


proc parseGPXTrack(trackxml : XmlNode): GPXTrack = 
    ## Internal proc. Parses the XML into a ``GPXTrack`` object.
    
    var track : GPXTrack = GPXTrack(link: @[], trkseg: @[])
    
    if trackxml.child("name") != nil:
        track.name = trackxml.child("name").innerText
    
    if trackxml.child("cmt") != nil:
        track.cmt = trackxml.child("cmt").innerText
    
    if trackxml.child("desc") != nil:
        track.desc = trackxml.child("desc").innerText
    
    if trackxml.child("src") != nil:
        track.src = trackxml.child("src").innerText
    
    for link in trackxml.findAll("link"):
        track.link.add(parseGPXLink(link))
    
    if trackxml.child("number") != nil:
        track.number = parseInt(trackxml.child("number").innerText)
    
    if trackxml.child("type") != nil:
        track.trackType = trackxml.child("type").innerText
    
    if trackxml.child("extensions") != nil:
        track.extensions = trackxml.child("extensions")
    
    for trackseg in trackxml.findAll("trkseg"):
        track.trkseg.add(parseGPXTrackSegment(trackseg))
    
    return track


proc parseGPXTrackSegment(segxml : XmlNode): GPXTrackSegment = 
    ## Internal proc. Parses the XML into a ``GPXTrackSegment`` object.
    
    var seg : GPXTrackSegment = GPXTrackSegment(trkpt: @[])
    
    for waypoint in segxml.findAll("trkpt"):
        seg.trkpt.add(parseGPXWaypoint(waypoint))
    
    if segxml.child("extensions") != nil:
        seg.extensions = segxml.child("extensions")
    
    return seg


proc parseGPX*(data : string): GPX = 
    ## Parses a GPX file from the given ``data``.
    
    var g : GPX = GPX(waypoints: @[], routes: @[], tracks: @[])
    var xml : XmlNode = parseXML(newStringStream(data))
    
    if xml.attr("version") != "1.1":
        raise newException(GPXError, "parseGPX(): unexpected GPX version (expected 1.1, got " & xml.attr("version") & ")")
    
    g.version = "1.1"
    g.creator = xml.attr("creator")
    if xml.child("extensions") != nil:
        g.extensions = xml.child("extensions")
    
    if xml.child("metadata") != nil:
        g.metadata = parseGPXMetadata(xml.child("metadata"))
    
    for waypoint in xml.findAll("wpt"):
        g.waypoints.add(parseGPXWaypoint(waypoint))
    
    for route in xml.findAll("rte"):
        g.routes.add(parseGPXRoute(route))
    
    for track in xml.findAll("trk"):
        g.tracks.add(parseGPXTrack(track))
        
    return g
