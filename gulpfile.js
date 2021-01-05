/**
 * Created by user on 6/13/2017.
 */

var gulp = require('gulp'),
    sass = require('gulp-sass'),
    uglify = require('gulp-uglify'),
    cleancss = require('gulp-clean-css'),
    concat = require('gulp-concat'),
    sourcemaps = require('gulp-sourcemaps'),
    browserSync = require('browser-sync').create(),
    autoPrefixer = require('gulp-autoprefixer'),
    gulpInject = require('gulp-inject'),
    series = require("stream-series"),
    del = require('del'),
    merge = require('merge-stream'),
    tinypngs = require('gulp-tinypng-compress');

/* injection stream */
var css = gulp.src(['./src/css/**/*.css', './src/style.css'], { read: false }),
    js = gulp.src(['./src/js/**/jquery/*.js', './src/js/vendor/*.js', './src/js/*.js'], { read: false }),
    image = gulp.src(['./src/images/**.{png,jpg,jpeg}']),
    fonts = gulp.src('./src/fonts/**');


/* optimize images */
gulp.task('imageOptimize', function () {
    var img = image.pipe(
        tinypngs({
            key: 'YOUR_KEY', // TO KNOW MORE SEE THE DOCUMENTATION
            sigFile: 'src/images/.tinypng-sigs',
            log: true
        })
    )
        .pipe(gulp.dest('./build/images'));

    var other = gulp.src('src/images/**/*')
        .pipe(gulp.dest('build/images'));
    return merge(img, other)
});

/*  */
gulp.task('distImageOptimize', function () {
    var imgs = image.pipe(
        tinypngs({
            key: 'YOUR_KEY', // TO KNOW MORE PLEASE SEE THE DOCUMENTATION
            log: true
        })
    )
        .pipe(gulp.dest('./dist/images'));

    var other = gulp.src('src/images/**/*')
        .pipe(gulp.dest('dist/images'));
    return merge(imgs, other)
});

/* move fonts */
gulp.task('fonts', function () {
    fonts.pipe(gulp.dest('./build/fonts'))
});

/*  */
gulp.task('distFonts', function () {
    fonts.pipe(gulp.dest('./dist/fonts'))
});

/* build css */
gulp.task('buildCss', function () {
    var plugins = gulp.src(['./src/css/**/*.css'])
        .pipe(cleancss())
        .pipe(gulp.dest('./build/css'));

    var mainCss = gulp.src('./src/style.css')
        .pipe(cleancss())
        .pipe(gulp.dest('./build'));

    return merge(plugins, mainCss);
});

/* build js */
gulp.task('buildJs', function () {
    return gulp.src('./src/js/**/**/*.js')
        .pipe(uglify())
        .pipe(gulp.dest('./build/js'));
});

/* build inject */
gulp.task('buildInject', ['buildCss', 'buildJs'], function () {
    var pluginb = gulp.src('./src/*.html')
        .pipe(gulpInject(series(css, js), { relative: true }))
        .pipe(gulp.dest('./build'));

    var jsUtilb = gulp.src('./src/js/vendor/ui/*')
        .pipe(gulp.dest('./build/js/vendor/ui'));
});


/* distribution plugin assets bundle */
gulp.task('distPlugins', function () {
    var jsPlugins = gulp.src(['./src/js/vendor/jquery/*.js', './src/js/vendor/*.js'])
        .pipe(uglify())
        .pipe(concat('plugins.min.js'))
        .pipe(gulp.dest('./dist/js'));

    var pluginCss = gulp.src('./src/css/**/*')
        .pipe(cleancss())
        .pipe(concat('plugins.min.css'))
        .pipe(gulp.dest('dist/css'));

    var jsAsset = gulp.src('./src/js//vendor/ui/*')
        .pipe(gulp.dest('./src/js/vendor/ui'))

    return merge(jsPlugins, pluginCss, jsAsset);
});

/* martplace css/js */
gulp.task('martAssets', function () {
    var martJs = gulp.src(['src/js/*.js'])
        .pipe(concat('script.min.js'))
        .pipe(gulp.dest('dist/js'));

    var martCss = gulp.src('src/style.css')
        .pipe(cleancss())
        .pipe(gulp.dest('dist'));
    var martHtml = gulp.src('./src/*.html')
        .pipe(gulp.dest('dist'));

    return merge(martJs, martCss, martHtml);
});

/* Sass Compiler */
gulp.task('sass', function () {
    gulp.src('./src/sass/**/*.scss')
        .pipe(sourcemaps.init())
        .pipe(sass({ outputStyle: 'expanded' }).on('error', sass.logError))
        .pipe(autoPrefixer('last 10 versions'))
        .pipe(sourcemaps.write('./src/map'))
        .pipe(gulp.dest('./src'))
        .pipe(browserSync.reload({
            stream: true
        }))
});

/* gulp serve content browser */
gulp.task('serve', function () {
    browserSync.init({
        server: {
            baseDir: './src'
        }
    })
});

/* default task for gulp during development */
gulp.task('default', ['serve', 'sass'], function () {
    gulp.watch('./src/sass/**/*.scss', ['sass']);
    gulp.watch('./src/*.html', browserSync.reload);
    gulp.watch('./src/js/**/*.js', browserSync.reload);
});

/* inject assets to html files */
gulp.task('inject', function () {
    var target = gulp.src('./src/*.html');
    target.pipe(gulpInject(series(js, css), { relative: true }))
        .pipe(gulp.dest('./src'));
});

/* build task */
gulp.task('build', ['sass', 'fonts', 'buildInject', 'imageOptimize']);

/* distribution bundling distImageOptimize*/
gulp.task('dist', ['sass', 'distPlugins', 'martAssets', 'distFonts'], function () {
    return gulp.src('./dist/*.html')
        .pipe(
            gulpInject(gulp.src(['dist/js/**', 'dist/css/**', 'dist/style.css']), { relative: true })
        )
        .pipe(gulp.dest('dist'))
});