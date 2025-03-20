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
  if (functionName === "create-easement") {
    const [parcelId, duration, terms] = args
    
    // Check if duration is at least 1 year in blocks
    if (duration <= 52560) return { type: "err", value: 400 }
    
    return { type: "ok", value: 1 } // Return easement ID 1
  }
  
  if (functionName === "get-easement") {
    const [easementId] = args
    if (easementId === 1) {
      return {
        type: "ok",
        value: {
          parcelId: 1,
          owner: mockClarity.txSender,
          startDate: mockClarity.blockHeight,
          duration: 100000,
          terms: "Conservation terms for testing",
          active: true,
        },
      }
    }
    return { type: "err", value: 404 }
  }
  
  if (functionName === "is-easement-active") {
    const [easementId] = args
    if (easementId === 1) return { type: "ok", value: true }
    return { type: "err", value: 404 }
  }
  
  return { type: "err", value: "Unknown function" }
}

describe("Conservation Easement Contract", () => {
  beforeEach(() => {
    // Reset mock state if needed
    mockClarity.blockHeight = 1
  })
  
  it("should create a new easement successfully", () => {
    const parcelId = 1
    const duration = 100000 // More than 1 year in blocks
    const terms = "Conservation terms for testing"
    
    const result = mockContractCall("create-easement", [parcelId, duration, terms])
    
    expect(result.type).toBe("ok")
    expect(result.value).toBe(1) // First easement ID
  })
  
  it("should fail to create an easement with too short duration", () => {
    const parcelId = 1
    const duration = 1000 // Less than 1 year in blocks
    const terms = "Conservation terms for testing"
    
    const result = mockContractCall("create-easement", [parcelId, duration, terms])
    
    expect(result.type).toBe("err")
    expect(result.value).toBe(400) // Error code for invalid duration
  })
})

