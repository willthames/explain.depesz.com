( function( $ ) {

    var Explain = {

        init : function( ) {

            return this.each( function( ) {

                $( this ).find( 'tbody tr' ).each( function( ) {

                    var row = $( this );

                    $.map( [ 'mouseover', 'mouseout', 'click' ], function( event, i ) {
                        row.bind( event, function( e ) {
                            Explain[ '_' + event ].apply( row, [ e ] );
                        } );
                    } );

                } );

            } );

        },

        _mouseover : function( e ) {

            this.addClass( 'hover' );

            var level = parseInt( this.attr( 'data-level' ) );

            this.nextAll( ).each( function( i, row ) {

                var r = $( row );

                var l = r.attr( 'data-level' )

                if ( l == level ) return false;

                if ( l == level + 1 )
                    r.addClass( 'sub-n' );
            } );
        },

        _mouseout : function( e ) {

            this.removeClass( 'hover' );

            this.parent( ).find( '.sub-n' ).removeClass( 'sub-n' );
        },

        _click : function( e ) {

            var isCollapsed = this.hasClass( 'collapsed' ) ? true : false;

            var level = parseInt( this.attr( 'data-level' ) );

            var affected = 0;

            this.nextAll( ).each( function( i, row ) {

                var r = $( row );

                var l = r.attr( 'data-level' );

                if ( l <= level ) return false;

                affected++;

                if ( isCollapsed ) {

                    r.show( );

                    return true;
                }

                r.hide( );

                r.removeClass( 'collapsed' );

            } );

            if ( ! affected ) return;

            this.toggleClass( 'collapsed' );
        },

        toggleColumn : function( column, a ) {

            var a = $( a );

            var table = a.parents( 'table' ).get( 0 );

            if ( !table ) return;

            table = $( table );

            table.find( 'td.' + column ).toggleClass( 'tight' );
            table.find( 'th.' + column ).toggleClass( 'tight' );
        },

        colorize : function( column, a ) {

            var a = $( a );

            var table = $( a ).parents( 'table' ).get( 0 );

            table = $( table );

            table.find( 'tbody tr.n' ).map( function( i, row ) {

                row = $( row );

                row.removeClass( 'c-1 c-2 c-3 c-4 c-mix' );

                value = 'mix';

                if ( column ) value = row.attr( 'data-' + column );

                row.addClass( 'c-' + value );

            } );

        },

        toggleView : function( view ) {

            var link = $( this );

            if ( link.hasClass( 'current' ) ) return;

            link.parents( 'ul' ).find( 'a' ).removeClass( 'current' );

            link.addClass( 'current' );

            var result = $( link.parents( 'div.result' ).get( 0 ) );

            if ( 'text' == view.toLowerCase( ) ) {
                result.find( 'div.result-html' ).hide( );
                result.find( 'div.result-text' ).show( );
                return;
            }

            result.find( 'div.result-html' ).show( );
            result.find( 'div.result-text' ).hide( );
        }
    };

    // public
    $.fn.explain = function( method ) {

        // what are you doing?
        if (        method
          && typeof method.substr == 'function'
          &&        method.substr( 0, 1 ) == '_' ) {

            $.error( 'Method ' + method + ' is private' );
        }

        // usage: $( element/selector ).explain( 'method' [, arguments ] );
        if ( Explain[ method ] ) {

            // "proxy" to: Explain[ 'method' ]( ... )
            return Explain[method].apply( this, Array.prototype.slice.call( arguments, 1 ));

        // usage: $( 'table#id' ).explain( );
        } else if ( typeof method === 'object' || ! method ) {

            // "proxy" to: Explain.init( ... )
            return Explain.init.apply( this, arguments );

        // ...what can I do?
        } else {

            // exception
            $.error( 'Method ' +  method + ' does not exist on jQuery.explain' );
        }

  };

} )( jQuery );
