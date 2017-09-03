#!/usr/bin/env node

// COPY this file to project's .bin dir!

/**
 * 基于 https://github.com/punkave/mechanic 修改
 *
 * 移除了 set() 方法 和 prettiest 依赖, 添加了 ROOT_DIR 变量
 *
 * PS: 这个老外的代码 真是烂！！！ 重构了好久!!!!
 */

'use strict';

const _ = require('lodash');
const argv = require('../lib/boring')();
const fs = require('fs');
const shelljs = require('shelljs');
const shellEscape = require('../lib/shell-escape');
const nunjucks = require('nunjucks');
const stringifiers = require('../lib/utils').stringifiers;

const ROOT_DIR = require('../lib/app-root').get();

///////// private ////////

function _replaceRootDirToRootPath(obj) {
  Object.keys(obj).forEach(key => {
    const value = obj[key];
    if (typeof value !== 'string') {
      return;
    }
    obj[key] = value.replace('ROOT_DIR', ROOT_DIR);
  });
  return obj;
}

function _loadConfigData() {
  const cfgDataFile = argv.config;

  if (!cfgDataFile) {
    throw new Error('Must set cfgDataFile using --config');
  }

  const config = require(`${ROOT_DIR}/${cfgDataFile}`);

  config.sites = config.sites || [];

  config.settings = _replaceRootDirToRootPath(config.settings);

  return config;
}

function _log(msg) {
  console.log(`[op-nginx] ${msg}`);
}

///////// command ////////

const cmds = {};

cmds.setup = function() {
  const config = _loadConfigData();
  const sites = _.filter(config.sites, site => {
    if (!(site.backends && site.backends.length) && !site.static) {
      _log(
        'WARNING: skipping ' + site.shortname + ' because no backends have been specified (hint: --backends=portnumber)'
      );
      return false;
    }
    return true;
  });

  sites.forEach(siteConf => {
    _replaceRootDirToRootPath(siteConf);
  });

  const template = fs.readFileSync(config.settings.template, 'utf8');

  // Set up include-able files to allow
  // easy customizations
  _.each(sites, function(site) {
    let folder = config.settings.overrides;
    if (!fs.existsSync(folder)) {
      fs.mkdirSync(folder);
    }
    folder += '/' + site.shortname;
    if (!fs.existsSync(folder)) {
      fs.mkdirSync(folder);
    }
    const files = ['location', 'proxy', 'server', 'top'];
    _.each(files, function(file) {
      const filename = folder + '/' + file;
      if (!fs.existsSync(filename)) {
        fs.writeFileSync(filename, '# Your custom nginx directives go here\n');
      }
    });
  });

  const nginxConfContent = nunjucks.renderString(template, {
    sites: sites,
    settings: config.settings,
    ROOT_DIR
  });

  fs.writeFileSync(config.settings.conf, nginxConfContent);

  _log(`Successfully generat nginx config files in ${config.settings.conf}`);
};

// function set() {
//   // Top-level settings: nginx conf folder, logs folder,
//   // and restart command
//   if (argv._.length !== 3) {
//     usage('The \"set\" command requires two parameters:\n\nmechanic set key value');
//   }
//   var key = argv._[1];
//   var value = argv._[2];
//   config.settings[key] = value;
//   cmds.reload();
// }

cmds.start = function() {
  const config = _loadConfigData();

  if (!config.settings.start) {
    return;
  }

  this.setup();

  const start = config.settings.start;
  if (shelljs.exec(start).code !== 0) {
    throw new Error(`ERROR: unable to start nginx using '${start}' !`);
  }

  _log(`Successfully reload nginx using ${start}`);

  process.exit(0);
};

cmds.reload = function() {
  const config = _loadConfigData();

  cmds.setup();

  const reload = config.settings.restart;
  if (shelljs.exec(reload).code !== 0) {
    throw new Error(`ERROR: unable to reload nginx using '${reload}' !`);
  }

  _log(`Successfully reload nginx using ${reload}`);

  // Under 0.12 (?) this doesn't want to terminate on its own,
  // not sure who the culprit is
  process.exit(0);
};

/**
 * Need argv:
 *
 * --site=site.shortname
 * --backends=list of backend
 */
cmds.upstreamTo = function() {
  const config = _loadConfigData();

  config.sites.forEach(site => {
    if (site.shortname === argv.site) {
      site.backends = argv.backends.split(',');
    }
  });

  cmds.reload();
};

const options = {
  host: 'string',
  backends: 'addresses',
  aliases: 'strings',
  canonical: 'boolean',
  default: 'boolean',
  static: 'string',
  autoindex: 'boolean',
  https: 'boolean',
  'redirect-to-https': 'boolean'
};

cmds.listConfigs = function() {
  const config = _loadConfigData();

  _.each(config.settings, function(val, key) {
    _log(shellEscape(['mechanic', 'set', key, val]));
  });
  _.each(config.sites, function(site) {
    const words = ['mechanic', 'add', site.shortname];
    _.each(site, function(val, key) {
      if (_.has(stringifiers, options[key])) {
        words.push('--' + key + '=' + stringifiers[options[key]](val));
      }
    });
    _log(shellEscape(words));
  });
};

cmds.usage = function() {
  _log('Every command MUST have at least one arg: --config');
  process.exit(0);
};

////////// run //////////

const command = argv._[0] || 'usage';

if (!cmds[command]) {
  throw new Error(`No such command: ${command} `);
}

cmds[command]();
