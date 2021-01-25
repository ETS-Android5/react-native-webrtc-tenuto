import { NativeModules } from 'react-native';
import MediaStreamTrack from './MediaStreamTrack';


//FLAG: 원래는 RTCRtpSender.js에 포함되어야하는 내용인데 2에서 이렇게 구현함.
// 잘못구현한게 맞음. 근데 일단 나머지 함수들이 잘 동작하는지 확인하기 위해서 일단 임시로 이거 추가.
// 이걸 왜 왜 이렇게 구현했지.... 오히려 더 복잡할텐데...
// 나중에 PION의 코드를 참고해서 이쪽걸 수정해보자.
export default class RtpSender {
    _id: String;
    _track: MediaStreamTrack;

    constructor(id, track) {
        this._id = id;
        this._track = track;
    }
    id = () => {
      return this._id;
    }
    track = () => {
      return _track;
    }
}