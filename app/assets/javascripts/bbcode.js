/*global HANDLEBARS_TEMPLATES:true md5:true*/

/**
  Support for BBCode rendering

  @class BBCode
  @namespace Markdown
  @module Markdown
**/
Markdown.BBCode = {

  QUOTE_REGEXP: /\[quote=([^\]]*)\]((?:[\s\S](?!\[quote=[^\]]*\]))*?)\[\/quote\]/im,

  // Define our replacers
  replacers: {
    base: {
      withoutArgs: {
        "ol": function(_, content) { return "<ol>" + content + "</ol>"; },
        "li": function(_, content) { return "<li>" + content + "</li>"; },
        "ul": function(_, content) { return "<ul>" + content + "</ul>"; },
        "code": function(_, content) { return "<pre>" + content + "</pre>"; },
        "url": function(_, url) { return "<a href=\"" + url + "\">" + url + "</a>"; },
        "email": function(_, address) { return "<a href=\"mailto:" + address + "\">" + address + "</a>"; },
        "img": function(_, src) { return "<img src=\"" + src + "\">"; }
      },
      withArgs: {
        "url": function(_, href, title) { return "<a href=\"" + href + "\">" + title + "</a>"; },
        "email": function(_, address, title) { return "<a href=\"mailto:" + address + "\">" + title + "</a>"; },
        "color": function(_, color, content) {
          if (!/^(\#[0-9a-fA-F]{3}([0-9a-fA-F]{3})?)|(aqua|black|blue|fuchsia|gray|green|lime|maroon|navy|olive|purple|red|silver|teal|white|yellow)$/.test(color)) {
            return content;
          }
          return "<span style=\"color: " + color + "\">" + content + "</span>";
        }
      }
    },

    // For HTML emails
    email: {
      withoutArgs: {
        "b": function(_, content) { return "<b>" + content + "</b>"; },
        "i": function(_, content) { return "<i>" + content + "</i>"; },
        "u": function(_, content) { return "<u>" + content + "</u>"; },
        "s": function(_, content) { return "<s>" + content + "</s>"; },
        "spoiler": function(_, content) { return "<span style='background-color: #000'>" + content + "</span>"; }
      },
      withArgs: {
        "size": function(_, size, content) { return "<span style=\"font-size: " + size + "px\">" + content + "</span>"; }
      }
    },

    // For sane environments that support CSS
    "default": {
      withoutArgs: {
        "b": function(_, content) { return "<span class='bbcode-b'>" + content + "</span>"; },
        "i": function(_, content) { return "<span class='bbcode-i'>" + content + "</span>"; },
        "u": function(_, content) { return "<span class='bbcode-u'>" + content + "</span>"; },
        "s": function(_, content) { return "<span class='bbcode-s'>" + content + "</span>"; },
        "spoiler": function(_, content) { return "<span class=\"spoiler\">" + content + "</span>";
        }
      },
      withArgs: {
        "size": function(_, size, content) { return "<span class=\"bbcode-size-" + size + "\">" + content + "</span>"; }
      }
    }
  },

  /**
    Apply a particular set of replacers

    @method apply
    @param {String} text The text we want to format
    @param {String} environment The environment in which this
  **/
  apply: function(text, environment) {
    var replacer = Markdown.BBCode.parsedReplacers()[environment];
    // apply all available replacers
    replacer.forEach(function(r) {
      text = text.replace(r.regexp, r.fn);
    });
    return text;
  },

  /**
    Lazy parse replacers

    @property parsedReplacers
  **/
  parsedReplacers: function() {
    if (this.parsed) return this.parsed;

    var result = {};

    _.each(Markdown.BBCode.replacers, function(rules, name) {

      var parsed = result[name] = [];

      _.each(_.extend(Markdown.BBCode.replacers.base.withoutArgs, rules.withoutArgs), function(val, tag) {
        parsed.push({ regexp: new RegExp("\\[" + tag + "\\]([\\s\\S]*?)\\[\\/" + tag + "\\]", "igm"), fn: val });
      });

      _.each(_.extend(Markdown.BBCode.replacers.base.withArgs, rules.withArgs), function(val, tag) {
        parsed.push({ regexp: new RegExp("\\[" + tag + "=?(.+?)\\]([\\s\\S]*?)\\[\\/" + tag + "\\]", "igm"), fn: val });
      });

    });

    this.parsed = result;
    return this.parsed;
  },

  /**
    Build the BBCode quote around the selected text

    @method buildQuoteBBCode
    @param {Markdown.Post} post The post we are quoting
    @param {String} contents The text selected
  **/
  buildQuoteBBCode: function(post, contents) {
    var contents_hashed, result, sansQuotes, stripped, stripped_hashed, tmp;
    if (!contents) contents = "";

    sansQuotes = contents.replace(this.QUOTE_REGEXP, '').trim();
    if (sansQuotes.length === 0) return "";

    result = "[quote=\"" + (post.get('username')) + ", post:" + (post.get('post_number')) + ", topic:" + (post.get('topic_id'));

    /* Strip the HTML from cooked */
    tmp = document.createElement('div');
    tmp.innerHTML = post.get('cooked');
    stripped = tmp.textContent || tmp.innerText;

    /*
      Let's remove any non alphanumeric characters as a kind of hash. Yes it's
      not accurate but it should work almost every time we need it to. It would be unlikely
      that the user would quote another post that matches in exactly this way.
    */
    stripped_hashed = stripped.replace(/[^a-zA-Z0-9]/g, '');
    contents_hashed = contents.replace(/[^a-zA-Z0-9]/g, '');

    /* If the quote is the full message, attribute it as such */
    if (stripped_hashed === contents_hashed) result += ", full:true";
    result += "\"]\n" + sansQuotes + "\n[/quote]\n\n";

    return result;
  },

  /**
    We want to remove quotes from a string before applying markdown to avoid
    weird stuff with newlines and such. This will return an object that
    contains a new version of the text with the quotes replaced with
    unique ids and `template()` function for reapplying them later.

    @method extractQuotes
    @param {String} text The text inside which we want to replace quotes
    @returns {Object} object containing the new string and template function
  **/
  extractQuotes: function(text) {
    var result = {text: "" + text, replacements: []};

    var replacements = []

    var matches;
    while (matches = Markdown.BBCode.QUOTE_REGEXP.exec(result.text)) {
      var key = md5(matches[0]);
      replacements.push({
        key: key,
        value: matches[0],
        content: matches[2].trim()
      });
      result.text = result.text.replace(matches[0], key + "\n");
    }

    result.template = function(input) {
      _.each(replacements,function(r) {
        var val = r.value.trim();
        val = val.replace(r.content, r.content.replace(/\n/g, '<br>'));
        input = input.replace(r.key, val);
      });
      return input;
    }

    return(result);
  },

  /**
    Replace quotes with appropriate markup

    @method formatQuote
    @param {String} text The text inside which we want to replace quotes
    @param {Object} opts Rendering options
  **/
  formatQuote: function(text, opts) {
    var args, matches, params, paramsSplit, paramsString, username;
    while (matches = this.QUOTE_REGEXP.exec(text)) {

      // The quote meta-data is contained in a json and included as a single attribute that is decoded by the quote directive
      // The quote content is included in the quoteblock body

      text = text.replace(matches[0],
        "</p><blockquote ce-quoted-comment class='quote' data-ce-quote='" + matches[1] + "'>" + matches[2].trim() + "</blockquote><p>"
      );

    }
    return text;
  },

  /**
    Format a text string using BBCode

    @method format
    @param {String} text The text we want to format
    @param {Object} opts Rendering options
  **/
  format: function(text, opts) {
    var environment = opts && opts.environment ? opts.environment : 'default';
    // Apply replacers for basic tags
    text = Markdown.BBCode.apply(text, environment);
    // Format
    text = Markdown.BBCode.formatQuote(text, opts);
    return text;
  }
};
