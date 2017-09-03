'use strict';

const parsers = {
  string: function(s) {
    return s.trim();
  },
  integer: function(s) {
    return parseInt(s, 10);
  },
  integers: function(s) {
    return _.map(parsers.strings(s), function(s) {
      return parsers.integer(s);
    });
  },
  addresses: function(s) {
    return _.map(parsers.strings(s), function(s) {
      var matches = s.match(/^(([^:]+)\:)?(\d+)$/);
      if (!matches) {
        throw 'A list of port numbers and/or address:port combinations is expected, separated by commas';
      }
      var host, port;
      if (matches[2]) {
        host = matches[2];
      } else {
        host = 'localhost';
      }
      port = matches[3];
      return host + ':' + port;
    });
  },
  strings: function(s) {
    return s.toString().split(/\s*\,\s*/);
  },
  boolean: function(s) {
    return s === 'true' || s === 'on' || s === 1;
  },
  // Have a feeling we'll use this soon
  keyValue: function(s) {
    s = parsers.string(s);
    var o = {};
    _.each(s, function(v) {
      var matches = v.match(/^([^:]+):(.*)$/);
      if (!matches) {
        throw 'Key-value pairs expected, like this: key:value,key:value';
      }
      o[matches[1]] = matches[2];
    });
    return o;
  }
};

const stringifiers = {
  string: function(s) {
    return s;
  },
  integer: function(s) {
    return s;
  },
  strings: function(s) {
    return s.join(',');
  },
  boolean: function(s) {
    return s ? 'true' : 'false';
  },
  keyValue: function(o) {
    return _.map(o, function(v, k) {
      return k + ':' + v;
    }).join(',');
  },
  addresses: function(s) {
    return s.join(',');
  }
};

module.exports = { parsers, stringifiers };
