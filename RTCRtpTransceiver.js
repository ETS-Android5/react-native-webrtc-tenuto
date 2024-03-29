import {NativeModules} from 'react-native';
import RTCRtpSender from './RTCRtpSender';
import RTCRtpReceiver from './RTCRtpReceiver';
import MediaStreamTrack from './MediaStreamTrack';

const {WebRTCModule} = NativeModules;

export default class RTCRtpTransceiver {
    _peerConnectionId: number;
    sender: RTCRtpSender;
    _receiver: RTCRtpReceiver

    _id: string;
    _mid: string | null;
    _direction: string;
    _currentDirection: string;
    _stopped: boolean;
    _mergeState: Function;

    constructor(pcId, state, mergeState) {
        // console.log("state.receiver.track:", state.receiver.track);
        this._peerConnectionId = pcId;
        this._id = state.id; // 이런게 어딨어.
        this._mid = state.mid ? state.mid : null;
        this._direction = state.direction;
        this._currentDirection = state.currentDirection;
        this._stopped = state.isStopped;
        this._mergeState = mergeState;
        let track = new MediaStreamTrack(state.receiver.track);
        this.sender = new RTCRtpSender(pcId, this._id, null, track); // 센치미터 수정
        this._receiver = new RTCRtpReceiver(state.receiver.id, track);
    }

    // 임의로 추가 https://www.w3.org/TR/webrtc/#dfn-transceiver-kind
    get kind(){
        return this._receiver.track.kind || undefined;
    }

    get id() {
        return this._id;
    }

    get mid() {
        return this._mid;
    }

    get isStopped() {
        return this._stopped;
    }

    get direction() {
        return this._direction;
    }

    set direction(val) {
        if (this._stopped) {
            throw Error('Transceiver Stopped');
        }
        this._direction = val;

        WebRTCModule.peerConnectionTransceiverSetDirection(this._peerConnectionId, this.id, val, (successful, data) => {
            if (successful) {
                this._mergeState(data.state);
            } else {
                console.warn("Unable to set direction: " + data);
            }
        });
    }

    get currentDirection() {
        return this._currentDirection;
    }

    // get sender() { 외부 접근을 위해 _ 뺌
    //     return this._sender;
    // }

    get receiver() {
        return this._receiver;
    }

    stop() {
        if (this._stopped) {
            return;
        }
        this._stopped = true;
        return new Promise((resolve, reject) => {
            WebRTCModule.peerConnectionTransceiverStop(this._peerConnectionId, this.id, (successful, data) => {
                if (successful) {
                    this._mergeState(data.state);
                    resolve();
                } else {
                    reject(new Error(data));
                }
            });
        });
    }

    _updateState(state) {
        this._mid = state.mid ? state.mid : null;
        this._direction = state.direction;
        this._currentDirection = state.currentDirection;
        if (state.isStopped) {
            this._stopped = true;
        }
    }
}
