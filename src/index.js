import {
	toolsBase,
	Pencil,
	Line,
	Eraser,
	Ellipse,
	Eyedropper,
	Pan,
	Rectangle,
	SelectShape,
	Text,
	Polygon,
} from './tools/index';
import * as actions from './actions';
import bindEvents from './bindEvents';
import * as canvasRenderer from './canvasRenderer';
import defaultOptions from './defaultOptions';
import lineEndCapShapes from './lineEndCapShapes';
import CanvasHelper from './CanvasHelper';
import * as localization from './localization';
import math from './math';
import renderSnapshotToImage from './renderSnapshotToImage';
import renderSnapshotToSVG from './renderSnapshotToSVG';
import * as shapes from './shapes';
import * as svgRenderer from './svgRenderer';
import TextRenderer from './TextRenderer';
import * as util from './util';

export {
	actions,
	bindEvents,
	canvasRenderer,
	defaultOptions,
	lineEndCapShapes,
	CanvasHelper,
	localization,
	math,
	renderSnapshotToImage,
	renderSnapshotToSVG,
	shapes,
	svgRenderer,
	TextRenderer,
	util,
	toolsBase,
	Pencil,
	Line,
	Eraser,
	Ellipse,
	Eyedropper,
	Pan,
	Rectangle,
	SelectShape,
	Text,
	Polygon,
};

export default CanvasHelper;
