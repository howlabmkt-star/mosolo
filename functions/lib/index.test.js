"use strict";
// Cloud Functions 단위 테스트
// 실행: cd functions && npx jest
Object.defineProperty(exports, "__esModule", { value: true });
const globals_1 = require("@jest/globals");
(0, globals_1.describe)('MBTI 캐시 키 로직', () => {
    const makeCacheKey = (a, b) => [a, b].sort().join('_');
    (0, globals_1.test)('순서 무관 동일 키 생성', () => {
        (0, globals_1.expect)(makeCacheKey('INFP', 'ENFJ')).toBe(makeCacheKey('ENFJ', 'INFP'));
    });
    (0, globals_1.test)('캐시 키 형식 확인', () => {
        (0, globals_1.expect)(makeCacheKey('INTJ', 'ENTP')).toBe('ENTP_INTJ');
    });
});
(0, globals_1.describe)('크레딧 상품 매핑', () => {
    const creditMap = {
        credit_1: 1,
        credit_5: 5,
        credit_10: 10,
    };
    (0, globals_1.test)('모든 상품 매핑 확인', () => {
        (0, globals_1.expect)(creditMap['credit_1']).toBe(1);
        (0, globals_1.expect)(creditMap['credit_5']).toBe(5);
        (0, globals_1.expect)(creditMap['credit_10']).toBe(10);
    });
    (0, globals_1.test)('없는 상품은 undefined', () => {
        (0, globals_1.expect)(creditMap['unknown']).toBeUndefined();
    });
});
//# sourceMappingURL=index.test.js.map