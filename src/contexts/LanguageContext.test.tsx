import React from 'react';
import { renderHook, act } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { LanguageProvider, useLanguage } from './LanguageContext';

describe('useLanguage', () => {
  it('should throw an error when used outside of LanguageProvider', () => {
    // Suppress console.error for this specific expected error test
    const consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {});

    expect(() => renderHook(() => useLanguage())).toThrowError(
      'useLanguage must be used within LanguageProvider'
    );

    consoleErrorSpy.mockRestore();
  });

  it('should return context values when used within LanguageProvider', () => {
    const wrapper = ({ children }: { children: React.ReactNode }) => (
      <LanguageProvider>{children}</LanguageProvider>
    );

    const { result } = renderHook(() => useLanguage(), { wrapper });

    expect(result.current.lang).toBe('nl');
    expect(typeof result.current.setLang).toBe('function');
    expect(typeof result.current.t).toBe('function');

    // Test default translation
    expect(result.current.t('nav.home')).toBe('Home');
  });

  it('should update language and translations', () => {
    const wrapper = ({ children }: { children: React.ReactNode }) => (
      <LanguageProvider>{children}</LanguageProvider>
    );

    const { result } = renderHook(() => useLanguage(), { wrapper });

    act(() => {
      result.current.setLang('en');
    });

    expect(result.current.lang).toBe('en');
    expect(result.current.t('nav.home')).toBe('Home'); // both nl and en have 'Home' for nav.home
    expect(result.current.t('about.tag')).toBe('About me'); // 'Over mij' in nl, 'About me' in en
  });
});
