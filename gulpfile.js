const gulp = require('gulp')
const zip = require('gulp-zip')
const replace = require('gulp-replace')
const newer = require('gulp-newer')
const dateformat = require('dateformat')
const del = require('del')
const packageJson = require('./package.json')
const bump = require('gulp-bump')
const fs = require('fs')
const exist = require('@existdb/gulp-exist')
const existConfig = require('./existConfig.json')
const existClient = exist.createClient(existConfig)
const gitInfo = require('git-rev-sync')
const simpleGit = require('simple-git')
const git = simpleGit()

// variables
const sourcePath = 'source'
const existPackageName = packageJson.name



//handles xqueries
gulp.task('xql', function(){

    return gulp.src(sourcePath + '/xql/**/*')
        .pipe(newer('build/resources/xql/'))
        .pipe(gulp.dest('build/resources/xql/'))
})

gulp.task('xqm', function(){

  const target = 'http://localhost:8080/exist/apps/api'

  return gulp.src(sourcePath + '/xqm/**/*')
    .pipe(newer('build/resources/xqm/'))
    .pipe(replace('$$deployTarget$$', target))
    .pipe(gulp.dest('build/resources/xqm/'))
})

gulp.task('xqm-public', function(){

  const branch = gitInfo.branch()
  const target = (branch === 'main') ? 'https://api.beethovens-werkstatt.de' : 'https://dev-api.beethovens-werkstatt.de'

  return gulp.src(sourcePath + '/xqm/**/*')
    .pipe(newer('build/resources/xqm/'))
    .pipe(replace('$$deployTarget$$', target))
    .pipe(gulp.dest('build/resources/xqm/'))
})

//deploys xql to exist-db
gulp.task('deploy-xql', gulp.series('xql', function() {

    return gulp.src(['**/*'], {cwd: 'build/resources/xql/'})
        .pipe(existClient.newer({target: '/db/apps/' + existPackageName + '/resources/xql/'}))
        .pipe(existClient.dest({target: '/db/apps/' + existPackageName + '/resources/xql/'}))
}))

//deploys xqm to exist-db
gulp.task('deploy-xqm', gulp.series('xqm', function() {

    return gulp.src(['**/*'], {cwd: 'build/resources/xqm/'})
        .pipe(existClient.newer({target: '/db/apps/' + existPackageName + '/resources/xqm/'}))
        .pipe(existClient.dest({target: '/db/apps/' + existPackageName + '/resources/xqm/'}))
}))

//watches xql for changes
gulp.task('watch-xql',function() {
    return gulp.watch([sourcePath + '/xql/**/*',sourcePath + '/xqm/**/*'], gulp.series('deploy-xql'))
})

//handles controller changes
gulp.task('controller', function(){

    return gulp.src(sourcePath + '/eXist-db/controller.xql')
        .pipe(newer('build/'))
        .pipe(gulp.dest('build/'))
})

//deploys xql to exist-db
gulp.task('deploy-controller', gulp.series('controller', function() {

    return gulp.src(['controller.xql'], {cwd: 'build/'})
        .pipe(existClient.newer({target: '/db/apps/' + existPackageName + '/'}))
        .pipe(existClient.dest({target: '/db/apps/' + existPackageName + '/'}))
}))

//watches controller changes
gulp.task('watch-controller',function() {
    return gulp.watch(sourcePath + '/eXist-db/controller.xql', gulp.series('deploy-controller'))
})

//handles xslt
gulp.task('xslt', function(){
    return gulp.src('./source/xslt/**/*')
        .pipe(newer('./build/resources/xslt/'))
        .pipe(gulp.dest('./build/resources/xslt/'))
})

//deploys xslt to exist-db
gulp.task('deploy-xslt', gulp.series('xslt', function() {
    return gulp.src('**/*', {cwd: './build/resources/xslt/'})
        .pipe(existClient.newer({target: '/db/apps/' + existPackageName + '/resources/xslt/'}))
        .pipe(existClient.dest({target: '/db/apps/' + existPackageName + '/resources/xslt/'}))
}))

//watches xslt for changes
gulp.task('watch-xslt',function() {
    return gulp.watch(sourcePath + '/xslt/**/*', gulp.series('deploy-xslt'))
})

//handles html
gulp.task('html', function(){
    return gulp.src('./source/html/**/*')
        .pipe(newer('./build/'))
        .pipe(gulp.dest('./build/'))
})

//deploys html to exist-db
gulp.task('deploy-html', gulp.series('html', function() {
    return gulp.src('**/*.html', {cwd: './build/'})
        .pipe(existClient.newer({target: '/db/apps/' + existPackageName + '/'}))
        .pipe(existClient.dest({target: '/db/apps/' + existPackageName + '/'}))
}))

//watches html for changes
gulp.task('watch-html',function() {
    return gulp.watch(sourcePath + '/html/**/*', gulp.series('deploy-html'))
})

//handles data
gulp.task('data', gulp.series(
    function() {
        return del(['./build/data/**/*','./build/tmp/**/*','./build/tmp'])
    },
    function(){
    
        const branch = gitInfo.branch()
        return git.clone('https://github.com/BeethovensWerkstatt/data.git', './build/tmp', {'--branch': branch})
        //return git.clone('https://github.com/BeethovensWerkstatt/data.git', './build/tmp')
    },
    function(){
      return gulp.src('./build/tmp/data/**/*')
          .pipe(gulp.dest('./build/data'))
    },
    function() {
        return del(['./build/tmp'])
    })
)

//bump version on patch level
/*gulp.task('bump-patch', function () {
    return gulp.src(['./package.json'])
        .pipe(bump({type: 'patch'}))
        .pipe(gulp.dest('./'))
})*/

//bump version on minor level
/*gulp.task('bump-minor', function () {
    return gulp.src(['./package.json'])
        .pipe(bump({type: 'minor'}))
        .pipe(gulp.dest('./'))
})*/

//bump version on major level
/*gulp.task('bump-major', function () {
    return gulp.src(['./package.json'])
        .pipe(bump({type: 'major'}))
        .pipe(gulp.dest('./'))
})*/

//set up basic xar structure
gulp.task('xar-structure', function() {
    return gulp.src(['./source/eXist-db/**/*'])
        .pipe(replace('$$deployed$$', dateformat(Date.now(), 'isoUtcDateTime')))
        .pipe(replace('$$version$$', getPackageJsonVersion()))
        .pipe(replace('$$desc$$', packageJson.description))
        .pipe(replace('$$license$$', packageJson.license))
        .pipe(replace('$$abbrev$$', packageJson.name))
        .pipe(gulp.dest('./build/'))

})

//empty build folder
gulp.task('del', function() {
    return del(['./build/**/*'])
})

//reading from fs as this prevents caching problems
function getPackageJsonVersion() {
    return JSON.parse(fs.readFileSync('./package.json', 'utf8')).version
}

gulp.task('git-info',function(done) {
    console.log('Git Information:')
    console.log('  short:    ' + gitInfo.short())
    console.log('  url:      ' + gitInfo.remoteUrl())
    console.log('  is dirty: ' + gitInfo.isDirty())
    console.log('  long:     ' + gitInfo.long())
    console.log('  branch:   ' + gitInfo.branch())
    console.log('  tag:      ' + gitInfo.tag())
    console.log('  date:     ' + gitInfo.date())
    done()
})

function getGitInfo() {
    return {short: gitInfo.short(),
            url: 'https://github.com/BeethovensWerkstatt/module2/commit/' + gitInfo.short(),
            dirty: gitInfo.isDirty()}
}


/**
 * deploys the current build folder into a (local) exist database
 */
gulp.task('deploy', function() {
    return gulp.src('**/*', {cwd: 'build'})
        .pipe(existClient.newer({target: '/db/apps/' + existPackageName + '/'}))
        .pipe(existClient.dest({target: '/db/apps/' + existPackageName + '/'}))
})

gulp.task('watch', gulp.parallel('watch-xql','watch-xslt','watch-controller','watch-html'))

gulp.task('dist-finish', function() {
    return gulp.src('./build/**/*')
        .pipe(zip(existPackageName + '-' + getPackageJsonVersion() + '.xar'))
        .pipe(gulp.dest('./dist'))
})

//creates a dist version
gulp.task('dist', gulp.series('xar-structure', gulp.parallel('xql','xqm-public','xslt','data','html'), 'dist-finish'))

gulp.task('dist-local', gulp.series('xar-structure', gulp.parallel('xql','xqm','xslt','data','html'), 'dist-finish'))


//creates a dist version and cleans up afterwards
gulp.task('dist-clean', gulp.series('dist', 'del'))

//creates a dist version with a version bump at patch level
/*gulp.task('dist-patch', gulp.series('bump-patch', 'dist'))*/

//creates a dist version with a version bump at minor level
/*gulp.task('dist-patch', gulp.series('bump-minor', 'dist'))*/

//creates a dist version with a version bump at major level
/*gulp.task('dist-patch', gulp.series('bump-major', 'dist']))*/


gulp.task('default', function() {
    console.log('')
    console.log('INFO: There is no default task, please run one of the following tasks:')
    console.log('')
    console.log('  "gulp dist"       : creates a xar from the current sources')
})
