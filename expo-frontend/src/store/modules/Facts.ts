import {
  createAsyncThunk,
  createEntityAdapter,
  createSlice,
  Dictionary,
  EntityId,
} from "@reduxjs/toolkit";
import { fetchFunFact } from "../../api";
import { FunFact } from "../../types";

interface FactsState {
  status: "loaded" | "loading" | "errored";
  error: Error | null;
  pendingFact?: FunFact;
  ids: EntityId[];
  entities: Dictionary<FunFact>;
}

const FactsAdapter = createEntityAdapter<FunFact>({
  selectId: (funFact) => funFact.fact,
});

export const getNewFact = createAsyncThunk<FunFact, number>(
  "facts/getNew",
  async (num) => {
    const factString = await fetchFunFact(num);
    return {
      fact: factString,
      rating: 0,
    };
  }
);

const initialState: FactsState = {
  status: "loaded",
  error: null,
  pendingFact: undefined,
  ...FactsAdapter.getInitialState(),
};

const FactsSlice = createSlice({
  name: "facts",
  initialState,
  reducers: {
    upsertFact: FactsAdapter.upsertOne,
  },
  extraReducers: (builder) => {
    builder.addCase(getNewFact.pending, (state) => {
      state.status = "loading";
      state.error = null;
    });
    builder.addCase(getNewFact.fulfilled, (state, action) => {
      state.status = "loaded";
      state.pendingFact = action.payload;
    });
    builder.addCase(getNewFact.rejected, (state, action) => {
      state.status = "errored";
      state.error = action.error as Error;
    });
  },
});

export const { upsertFact } = FactsSlice.actions;

export const { selectAll: selectAllFacts } = FactsAdapter.getSelectors();

export default FactsSlice.reducer;
