import { useEffect, useState } from "react";


export type RequestResult<T> = {
  caller: () => void;
  loading: boolean;
  error?: string;
  result?: T;
};

export function useRequestResult<T>(
  perform: (
    setResult: (result: T) => void,
    setError: (error: string) => void
  ) => T,
  args?: {
    useEffect: boolean;
  }
): RequestResult<T> {
  const [loading, setLoading] = useState(false);
  const [error, _setError] = useState(undefined as string | undefined);
  const [result, _setResult] = useState<T | undefined>(undefined);
  const setResult = (result: T) => {
    _setResult(result);
    _setError(undefined);
  };
  const setError = (error: string) => {
    _setResult(undefined);
    _setError(error);
  };

  const caller = () => {
    if (!loading) {
      setLoading(true);
      try {
        perform(setResult, setError);
      } catch (e) {
        setError(e.message);
      }
      setLoading(false);
    }
  };

  if (args?.useEffect) {
    useEffect(() => {
      if (!error && !result) {
        caller();
      }
    }, [loading, error, result]);
  }

  return {
    caller,
    loading,
    error,
    result,
  };
}
