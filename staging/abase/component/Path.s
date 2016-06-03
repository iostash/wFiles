(function(){

'use strict';

var Self = wTools;
var _ = wTools;

//

var _urlComponents =
{

  /* atomic */

  protocol : null,
  host : null,
  port : null,
  pathname : null,
  query : null,
  hash : null,

  /* composite */

  url : null, /* whole */
  hostname : null, /* host + port */
  origin : null, /* protocol + host + port */

}

//

/*
http://www.site.com:13/path/name?query=here&and=here#anchor
2 - protocol
3 - hostname( host + port )
5 - pathname
6 - query
8 - hash
*/

var urlParse = function( path,options )
{
  var result = {};
  var parse = /((\w+):\/\/)?([^\/]+)(([^?#]+)$|[$\?#])?([^#]+)?(\#(.*))?/;
  var options = options || {};

  _.assert( _.strIs( path ) );

  var e = parse.exec( path );
  if( !e )
  throw _.err( 'urlParse :','cant parse :',path );

  result.protocol = e[ 2 ];
  result.hostname = e[ 3 ];
  result.pathname = e[ 5 ];
  result.query = e[ 6 ];
  result.hash = e[ 8 ];

  var h = result.hostname.split( ':' );
  result.host = h[ 0 ];
  result.port = h[ 1 ];

  if( options.atomicOnly )
  delete result.hostname
  else
  result.origin = result.protocol + '://' + result.hostname;

  return result;
}

urlParse.components = _urlComponents;

//

var urlMake = function( components )
{
  var result = '';

  _.assertMapOnly( components,_urlComponents );

  if( components.url )
  {
    _.assert( _.strIs( components.url ) && components.url );
    return components.url;
  }

  if( _.strIs( components ) )
  return components;
  else if( !_.mapIs( components ) )
  throw _.err( 'unexpected' );

  if( components.origin )
  {
    result += origin;
  }
  else
  {

    if( components.protocol )
    result += components.protocol + ':';

    result += '//';

    if( components.hostname )
    result += components.hostname;
    else
    {
      if( components.host )
      result += components.host;
      else
      result += '127.0.0.1';
      result += ':' + components.port;
    }

  }

  if( components.pathname )
  result = _.urlJoin( result,components.pathname );

  _.assert( !components.query || _.strIs( components.query ) );
  if( components.query )
  result += '?' + components.query;

  if( components.hash )
  result += '#' + components.hash;

  return result;
}

urlMake.components = _urlComponents;

//

var urlFor = function( options )
{

  if( options.url )
  return urlMake( options );

  var url = urlServer();
  var o = _.mapScreens_( options,_urlComponents );

  if( !Object.keys( o ).length )
  return url;

  var parsed = urlParse( url,{ atomicOnly : 1 } );

  _.mapExtend( parsed,o );

  return urlMake( parsed );
}

//

var urlDocument = function( path,options )
{

  var options = options || {};

  if( path === undefined ) path = window.location.href;

  if( path.indexOf( '//' ) === -1 )
  {
    path = 'http:/' + ( path[0] === '/' ? '' : '/' ) + path;
  }

  var a = path.split( '//' );
  var b = a[ 1 ].split( '?' );

  //

  if( options.withoutServer )
  {
    var i = b[ 0 ].indexOf( '/' );
    if( i === -1 ) i = 0;
    return b[ 0 ].substr( i );
  }
  else
  {
    if( options.withoutProtocol ) return b[0];
    else return a[ 0 ] + '//' + b[ 0 ];
  }

}

//

var urlServer = function( path )
{
  var a,b;

  if( path === undefined )
  path = window.location.href;

  if( path.indexOf( '//' ) === -1 )
  {
    if( path[0] === '/' ) return '/';
    a = [ '',path ]
  }
  else
  {
    a = path.split( '//' );
    a[ 0 ] += '//';
  }

  b = a[ 1 ].split( '/' );

  return a[ 0 ] + b[ 0 ] + '/';
}

//

var urlQuery = function( path )
{

  if( path === undefined ) path = window.location.href;

  if( path.indexOf( '?' ) === -1 ) return '';
  return path.split( '?' )[ 1 ];
}

//

var urlDequery = function( query )
{

  var result = {};
  var query = query || window.location.search.split('?')[1];
  if( !query || !query.length ) return result;
  var vars = query.split("&");
  for( var i=0;i<vars.length;i++ ){

    var w = vars[i].split("=");
    w[0] = decodeURIComponent( w[0] );
    if( w[1] === undefined ) w[1] = '';
    else w[1] = decodeURIComponent( w[1] );

    if( (w[1][0] == w[1][w[1].length-1]) && ( w[1][0] == '"') )
    w[1] = w[1].substr( 1,w[1].length-1 );

    if( result[w[0]] === undefined ) {
      result[w[0]] = w[1];
    } else if( wTools.strIs( result[w[0]] )){
      result[w[0]] = result[result[w[0]], w[1]]
    } else {
      result[w[0]].push(w[1]);
    }

  }

  return result;
}

//

var urlIs = function( url )
{

  var p =
    '^(https?:\\/\\/)?'                                     // protocol
    + '(\\/)?'                                              // relative
    + '((([a-z\\d]([a-z\\d-]*[a-z\\d])*)\\.)+[a-z]{2,}|'    // domain
    + '((\\d{1,3}\\.){3}\\d{1,3}))'                         // ip
    + '(\\:\\d+)?'                                          // port
    + '(\\/[-a-z\\d%_.~+]*)*'                               // path
    + '(\\?[;&a-z\\d%_.~+=-]*)?'                            // query
    + '(\\#[-a-z\\d_]*)?$';                                 // anchor

  var pattern = new RegExp( p,'i' );
  return pattern.test( url );

}

//

var urlJoin = function()
{

  var result = _pathJoin( arguments,{ reroot : 0, url : 1 } );
  return result;
}

// --
// path
// --

var _pathJoin = function( pathes,options )
{
  var result = '';
  var optionsDefault =
  {
    reroot : 0,
    url : 0,
  }

  _.assertMapOnly( options,optionsDefault );

  for( var a = pathes.length-1 ; a >= 0 ; a-- )
  {

    if( !_.strIs( pathes[ a ] ) )
    throw _.err( 'wTools.pathJoin:','require strings as path, but #' + a + 'argument is ' + _.strTypeOf( pathes[ a ] ) );

    var src = pathes[ a ];

    if( !src ) continue;

    if( !options.url )
    src = src.replace( /\\/g,'/' );

    if( result && result[ 0 ] !== '/' ) result = '/' + result;
    if( result && src[ src.length-1 ] === '/' ) src = src.substr( 0,src.length-1 );

    result = src + result;

    //if( src.indexOf( '//' ) !== -1 ) return result;
    if( !options.reroot )
    {
      if( options.url )
      {
        if( src.indexOf( '//' ) !== -1 )
        return result;
      }
      else if( src[ 0 ] === '/' )
      {
        //if( options.url ) return urlServer( pathes[ 0 ] ) + result;
        //else
        return result;
      }
      if( !options.url )
      {
        if( src[ 1 ] === ':' ) return result;
      }
    }

  }

  //console.log( '_pathJoin',pathes,'->',result );

  return result;
}

//

var pathJoin = function()
{
  var result = _pathJoin( arguments,{ reroot : 0 } );

  if( _.pathNormalize )
  result = _.pathNormalize( result );

  return result;
}

//

var pathReroot = function()
{
  var result = _pathJoin( arguments,{ reroot : 1 } );
  return result;
}

//

var pathDir = function( path )
{

  if( !_.strIs( path ) )
  throw _.err( 'wTools.pathName:','require strings as path' );

  var i = path.lastIndexOf( '/' );

  if( i === -1 ) return path;

  if( path[ i - 1 ] === '/' ) return path;

  return path.substr( 0,i );
}

//

var pathExt = function( path )
{

  if( !_.strIs( path ) ) throw _.err( 'wTools.pathName:','require strings as path' );

  var index = path.lastIndexOf('/');
  if( index >= 0 ) path = path.substr( index+1,path.length-index-1  );
  var index = path.lastIndexOf('.');
  if( index === -1 ) return '';
  index += 1;
  return path.substr( index,path.length-index );

}

//

var pathPrefix = function( path )
{

  if( !_.strIs( path ) ) throw _.err( 'wTools.pathName:','require strings as path' );

  var n = path.lastIndexOf( '/' );
  if( n === -1 ) n = 0;

  var parts = [ path.substr( 0,n ),path.substr( n ) ];

  var n = parts[ 1 ].indexOf( '.' );
  if( n === -1 ) n = parts[ 1 ].length;

  var result = parts[ 0 ] + parts[ 1 ].substr( 0, n );
  //console.log( 'pathPrefix',path,'->',result );
  return result;
}

//

var pathName = function( path,options )
{

  if( !_.strIs( path ) )
  throw _.err( 'wTools.pathName:','require strings as path' );

  var options = options || {};
  if( options.withoutExtension === undefined )
  {
    options.withoutExtension = options.withExtension !== undefined ? !options.withExtension : true;
  }

  var i = path.lastIndexOf( '/' );
  if( i !== -1 ) path = path.substr( i+1 );

  if( options.withoutExtension )
  {
    var i = path.lastIndexOf( '.' );
    if( i !== -1 ) path = path.substr( 0,i );
  }

  return path;
}

//

var pathWithoutExt = function( path )
{

  var n = path.lastIndexOf( '.' );
  if( n === -1 ) n = path.length;
  var result = path.substr( 0, n );
  return result;
}

//

var pathChangeExt = function( path,ext )
{

  if( ext === '' ) return pathWithoutExt( path );
  else return pathWithoutExt( path ) + '.' + ext;

}

// --
// prototype
// --

var Proto =
{

  urlParse: urlParse,
  urlMake: urlMake,
  urlFor: urlFor,

  urlDocument: urlDocument,
  urlServer: urlServer,
  urlQuery: urlQuery,
  urlDequery: urlDequery,
  urlIs: urlIs,
  urlJoin: urlJoin,

  _pathJoin: _pathJoin,
  pathJoin: pathJoin,
  pathReroot: pathReroot,
  pathDir: pathDir,
  pathPrefix: pathPrefix,

  pathName: pathName,
  pathWithoutExt: pathWithoutExt,
  pathChangeExt: pathChangeExt,
  pathExt: pathExt,

  // var

  _urlComponents : _urlComponents,

};

_.mapExtend( wTools,Proto );

// export

if( typeof module !== 'undefined' )
{
  module['exports'] = Self;
}

})();