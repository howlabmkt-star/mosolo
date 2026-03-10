// Cloud Functions 단위 테스트
// 실행: cd functions && npx jest

import { describe, test, expect } from '@jest/globals';

describe('MBTI 캐시 키 로직', () => {
  const makeCacheKey = (a: string, b: string) => [a, b].sort().join('_');

  test('순서 무관 동일 키 생성', () => {
    expect(makeCacheKey('INFP', 'ENFJ')).toBe(makeCacheKey('ENFJ', 'INFP'));
  });

  test('캐시 키 형식 확인', () => {
    expect(makeCacheKey('INTJ', 'ENTP')).toBe('ENTP_INTJ');
  });
});

describe('크레딧 상품 매핑', () => {
  const creditMap: Record<string, number> = {
    credit_1: 1,
    credit_5: 5,
    credit_10: 10,
  };

  test('모든 상품 매핑 확인', () => {
    expect(creditMap['credit_1']).toBe(1);
    expect(creditMap['credit_5']).toBe(5);
    expect(creditMap['credit_10']).toBe(10);
  });

  test('없는 상품은 undefined', () => {
    expect(creditMap['unknown']).toBeUndefined();
  });
});
