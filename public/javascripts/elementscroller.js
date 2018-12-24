/**
 * Accordion Effect for Script.aculo.us
 * Created by Lucas van Dijk
 * http://www.return1.net
 *
 * Copyright 2007 by Lucas van Dijk
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 */

Effect.ScrollVertical = Class.create();

Object.extend(Object.extend(Effect.ScrollVertical.prototype, Effect.Base.prototype), 
{
	initialize: function(element) 
	{
		if(typeof element == "string")
		{		
			this.element = $(element);
			if(!this.element) 
			{
				throw(Effect._elementDoesNotExistError);
			}
		}
		
		var options = Object.extend({
			from: this.element.scrollTop || 0,
			to:   this.element.scrollHeight
		}, arguments[1] || {});
		
		options.to = options.to == this.element.scrollHeight ? options.to : options.from + options.to;
		
		this.start(options);
	},
	
	update: function(position) 
	{
		this.element.scrollTop = position;
	}
});

Effect.ScrollHorizontal = Class.create();

Object.extend(Object.extend(Effect.ScrollHorizontal.prototype, Effect.Base.prototype), 
{
	initialize: function(element) 
	{
		if(typeof element == "string")
		{		
			this.element = $(element);
			if(!this.element) 
			{
				throw(Effect._elementDoesNotExistError);
			}
		}
		
		var options = Object.extend({
			from: this.element.scrollLeft || 0,
			to:   this.element.scrollWidth
		}, arguments[1] || {});
		
		this.start(options);
	},
	
	update: function(position) 
	{
		this.element.scrollLeft = position;
	}
});
