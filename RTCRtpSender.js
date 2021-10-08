import {NativeModules} from 'react-native';
import MediaStreamTrack from './MediaStreamTrack';
// import RTCRtpParameters from './RTCRtpParameters';

const {WebRTCModule} = NativeModules;

export default class RTCRtpSender {
    _peerConnectionId: number;
    _transceiverId: String;
    id: String;
    // _mergeState: Function;
    track: MediaStreamTrack;

    params: RTCRtpParameters ;
    constructor(pcId: number, _transceiverId: String, id: String, t: MediaStreamTrack) {
        this._peerConnectionId = pcId;
        this._transceiverId = _transceiverId;
        this.id = id;
        // this.id = _transceiverId; // 센치미터 수정
        this.track = t;
    }

    // setParameter = (params: RTCRtpParameters) => {
    //     return new Promise((resolve, reject) => {
    //         WebRTCModule
    //     })
    // }
    getParameters = () => {
        return new Promise((resolve, reject)=>{
            if(!this.id){
                reject("Not initiated");
            }
            WebRTCModule.peerConnectionSenderGetParameters(this._peerConnectionId, this.id, (successful, data)=>{
                if(successful){
                    resolve(data);
                }else{
                    console.warn("getparameters 실패");
                    reject(data);
                }
            })
        })
    }

    // TODO: 다른 방법으로 Implement해야함.
    // replaceTrack = (track: MediaStreamTrack | null) => {
    //     return new Promise((resolve, reject) => {
    //         WebRTCModule.peerConnectionTransceiverReplaceTrack(this._transceiver._peerConnectionId, this._transceiver.id, track ? track.id : null, (successful, data) => {
    //             if (successful) {
    //                 this._transceiver._mergeState(data.state); // 왜 mergeState가 필요해. replace는 그게 필요없지않나.
    //                 resolve();
    //             } else {
    //                 reject(new Error(data));
    //             }
    //         });
    //     });
    // }
}
