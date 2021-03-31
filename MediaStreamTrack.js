'use strict';

import {NativeModules} from 'react-native';
import EventTarget from 'event-target-shim';
import MediaStreamErrorEvent from './MediaStreamErrorEvent';
import type MediaStreamError from './MediaStreamError';
import { deepClone } from './RTCUtil';

const {WebRTCModule} = NativeModules;

const MEDIA_STREAM_TRACK_EVENTS = [
  'ended',
  'mute',
  'unmute',
  // see: https://www.w3.org/TR/mediacapture-streams/#constrainable-interface
  'overconstrained',
];

type MediaStreamTrackState = "live" | "ended";

class MediaStreamTrack extends EventTarget(MEDIA_STREAM_TRACK_EVENTS) {
  _constraints: Object;
  _enabled: boolean;
  id: string;
  kind: string;
  label: string;
  muted: boolean;
  // readyState in java: INITIALIZING, LIVE, ENDED, FAILED
  readyState: MediaStreamTrackState;
  remote: boolean;

  onended: ?Function;
  onmute: ?Function;
  onunmute: ?Function;
  overconstrained: ?Function;

  constructor(info) {
    super();

    this._constraints = info.constraints || {};
    this._enabled = info.enabled;
    this.id = info.id;
    this.kind = info.kind;
    this.label = info.label;
    this.muted = false;
    this.remote = info.remote;

    const _readyState = info.readyState.toLowerCase();
    this.readyState = (_readyState === "initializing"
        || _readyState === "live") ? "live" : "ended";
  }

  get enabled(): boolean {
    return this._enabled;
  }

  set enabled(enabled: boolean): void {
    if (enabled === this._enabled) {
      return;
    }
    WebRTCModule.mediaStreamTrackSetEnabled(this.id, !this._enabled);
    this._enabled = !this._enabled;
    this.muted = !this._enabled;
  }

  stop() {
    WebRTCModule.mediaStreamTrackSetEnabled(this.id, false);
    this.readyState = 'ended';
    // TODO: save some stopped flag?
  }

  /**
   * Private / custom API for switching the cameras on the fly, without the
   * need for adding / removing tracks or doing any SDP renegotiation.
   *
   * This is how the reference application (AppRTCMobile) implements camera
   * switching.
   */
  _switchCamera() {
    if (this.remote) {
      throw new Error('Not implemented for remote tracks');
    }
    if (this.kind !== 'video') {
      throw new Error('Only implemented for video tracks');
    }
    WebRTCModule.mediaStreamTrackSwitchCamera(this.id);
  }

  /**
   * Filter Effect for Local Video Track
   * pass filter type through a parameter "string:filter"
   *
   * [filter types for iOS]
   * Tone Change: "CISepiaTone", "CIPhotoEffectFade", "CIPhotoEffectInstant", "CIPhotoEffectMono", "CIPhotoEffectNoir",
   *              "CIPhotoEffectProcess", "CIPhotoEffectTonal"
   * Various Effect: "CIEdgeWork", "CIComicEffect", "CIColorPosterize", "CIColorInvert"
   * (+) Upcoming: "CIBloom", "CIGloom", "CICrystallize"
   *
   * Filter type will be updated often.
  * */
  setFilter(filter) {
    WebRTCModule.mediaStreamTrackSetFilter(this.id, filter);
  }

  applyConstraints() {
    throw new Error('Not implemented.');
  }

  clone() {
    throw new Error('Not implemented.');
  }

  getCapabilities() {
    throw new Error('Not implemented.');
  }

  getConstraints() {
    return deepClone(this._constraints);
  }

  getSettings() {
    throw new Error('Not implemented.');
  }
  toURL(){ // FLAG: 2에 있어서 추가함
    return this.id;
  }

  release() {
    WebRTCModule.mediaStreamTrackRelease(this.id);
  }
}

export default MediaStreamTrack;
