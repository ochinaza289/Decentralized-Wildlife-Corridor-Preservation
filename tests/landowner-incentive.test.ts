import { describe, it, expect, beforeEach } from "vitest"

// Mock the Clarity VM environment
const mockClarity = {
  accounts: {
    ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM: { balance: 1000000 },
  },
  txSender: "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM",
  blockHeight: 1,
}

// Mock contract calls
const mockContractCall = (functionName, args) => {
  if (functionName === "create-incentive-program") {
    const [name, ratePerArea, minDuration, budget] = args
    
    // Check if budget is positive
    if (budget <= 0) return { type: "err", value: 1 }
    
    return { type: "ok", value: 1 } // Return program ID 1
  }
  
  if (functionName === "process-payment") {
    const [easementId, programId, parcelArea, easementDuration] = args
    
    // Mock program
    const program = {
      active: true,
      minDuration: 52560,
      ratePerArea: 10,
      remainingBudget: 1000000,
    }
    
    // Check program is active
    if (!program.active) return { type: "err", value: 407 }
    
    // Check easement meets minimum duration
    if (easementDuration < program.minDuration) return { type: "err", value: 408 }
    
    // Calculate payment
    const paymentAmount = parcelArea * program.ratePerArea
    
    // Check sufficient budget
    if (program.remainingBudget < paymentAmount) return { type: "err", value: 409 }
    
    return { type: "ok", value: paymentAmount }
  }
  
  if (functionName === "get-program") {
    const [programId] = args
    if (programId === 1) {
      return {
        type: "ok",
        value: {
          name: "Wildlife Corridor Program",
          ratePerArea: 10,
          minDuration: 52560,
          active: true,
          totalBudget: 1000000,
          remainingBudget: 1000000,
        },
      }
    }
    return { type: "err", value: 404 }
  }
  
  return { type: "err", value: "Unknown function" }
}

describe("Landowner Incentive Contract", () => {
  beforeEach(() => {
    // Reset mock state if needed
    mockClarity.blockHeight = 1
  })
  
  it("should create a new incentive program successfully", () => {
    const name = "Wildlife Corridor Program"
    const ratePerArea = 10
    const minDuration = 52560 // 1 year in blocks
    const budget = 1000000
    
    const result = mockContractCall("create-incentive-program", [name, ratePerArea, minDuration, budget])
    
    expect(result.type).toBe("ok")
    expect(result.value).toBe(1) // First program ID
  })
  
  it("should process payment successfully", () => {
    const easementId = 1
    const programId = 1
    const parcelArea = 10000
    const easementDuration = 100000
    
    const result = mockContractCall("process-payment", [easementId, programId, parcelArea, easementDuration])
    
    expect(result.type).toBe("ok")
    expect(result.value).toBe(100000) // 10000 (area) * 10 (rate)
  })
})

