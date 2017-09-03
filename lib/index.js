/**
 * 移除了 set() 方法 和 prettiest 依赖, 添加了 ROOT_DIR 变量
 *
 * PS: 这个老外的代码 真是烂！！！ 重构了好久!!!!
 */

'use strict';

require('yqj-commons');

const argv = require('./boring')();
const fs = require('fs');
const shelljs = require('shelljs');
const shellEscape = require('./shell-escape');
const nunjucks = require('nunjucks');
const stringifiers = require('./utils').stringifiers;

const cfgDataFile = argv.config;

if (!cfgDataFile) {
  throw new Error('Must set cfgDataFile using --config');
}

const ROOT_DIR = require('./app-root').get();

const data = require(`${ROOT_DIR}/${cfgDataFile}`);

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

const settings = _replaceRootDirToRootPath(data.settings);

data.sites = data.sites || [];

///////// command ////////

const cmds = {};

cmds.usage = function(m) {
  if (m) {
    log(m);
  }
  log('See https://github.com/punkave/mechanic for usage.');
  process.exit(0);
};

cmds.setup = function() {
  const sites = _.filter(data.sites, site => {
    if (!(site.backends && site.backends.length) && !site.static) {
      log(
        'WARNING: skipping ' + site.shortname + ' because no backends have been specified (hint: --backends=portnumber)'
      );
      return false;
    }
    return true;
  });

  sites.forEach(siteConf => {
    _replaceRootDirToRootPath(siteConf);
  });

  const template = fs.readFileSync(settings.template, 'utf8');

  // Set up include-able files to allow
  // easy customizations
  _.each(sites, function(site) {
    let folder = settings.overrides;
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
    settings: settings,
    ROOT_DIR
  });

  fs.writeFileSync(settings.conf, nginxConfContent);

  log(`Successfully generat nginx config files in ${settings.conf}`);
};

// function set() {
//   // Top-level settings: nginx conf folder, logs folder,
//   // and restart command
//   if (argv._.length !== 3) {
//     usage('The \"set\" command requires two parameters:\n\nmechanic set key value');
//   }
//   var key = argv._[1];
//   var value = argv._[2];
//   data.settings[key] = value;
//   cmds.reload();
// }

cmds.start = function() {
  if (!settings.start) {
    return;
  }

  this.setup();

  const start = settings.start;
  if (shelljs.exec(start).code !== 0) {
    throw new Error(`ERROR: unable to start nginx using '${start}' !`);
  }

  log(`Successfully reload nginx using ${start}`);

  process.exit(0);
};

cmds.reload = function() {
  cmds.setup();

  const reload = settings.restart;
  if (shelljs.exec(reload).code !== 0) {
    throw new Error(`ERROR: unable to reload nginx using '${reload}' !`);
  }

  log(`Successfully reload nginx using ${reload}`);

  // Under 0.12 (?) this doesn't want to terminate on its own,
  // not sure who the culprit is
  process.exit(0);
};

cmds.upstreamTo = function() {
  data.sites.forEach(site => {
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
  _.each(data.settings, function(val, key) {
    log(shellEscape(['mechanic', 'set', key, val]));
  });
  _.each(data.sites, function(site) {
    const words = ['mechanic', 'add', site.shortname];
    _.each(site, function(val, key) {
      if (_.has(stringifiers, options[key])) {
        words.push('--' + key + '=' + stringifiers[options[key]](val));
      }
    });
    log(shellEscape(words));
  });
};

////////// run //////////

const command = argv._[0] || 'usage';

if (!cmds[command]) {
  throw new Error(`No such command: ${command} `);
}

cmds[command]();
