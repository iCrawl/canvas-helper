var browserify = require('browserify');
var gulp = require('gulp');
var connect = require('gulp-connect');
var rename = require('gulp-rename');
var sass = require('gulp-ruby-sass');
var source = require('vinyl-source-stream');
var streamify = require('gulp-streamify')
var uglify = require('gulp-uglify');


gulp.task('sass', function() {
  return gulp.src('scss/literally.scss')
    .pipe(sass({ style: 'compressed' }))
    .pipe(gulp.dest('lib/css/literally.css'))
});


gulp.task('browserify', function() {
  var bundleStream = browserify({
      basedir: 'src', extensions: ['.js', '.coffee']
  }).add('./index.coffee')
    .external('React/addons')
    .external('React')
    .transform('coffeeify')
    .bundle({standalone: 'LC'})

  return bundleStream
    .pipe(source('./src/index.coffee'))
    //.pipe(streamify(uglify()))
    .pipe(rename('literallycanvas.js'))
    .pipe(gulp.dest('./lib/js/'));
});


gulp.task('uglify', ['browserify'], function() {
  gulp.src('./lib/js/literallycanvas.js')
    .pipe(uglify())
    .pipe(rename('literallycanvas.min.js'))
    .pipe(gulp.dest('./lib/js'))
});


gulp.task('default', ['uglify', 'sass'], function() {
});


gulp.task('watch', function() {
  gulp.watch(['src/*.coffee', 'src/*/*.coffee'], ['browserify']);
  gulp.watch('scss/*.scss', ['sass']);
});


gulp.task('serve', function() {
  connect.server({
    livereload: true
  });
});


gulp.task('dev', ['browserify', 'sass', 'watch', 'serve'], function() {
});