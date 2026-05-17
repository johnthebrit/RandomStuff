/// Quantum teleportation circuit, written without mid-circuit measurement
/// or classical branching so it remains compatible with current hardware
/// that only supports terminal measurements.
///
/// The classically-controlled corrections (X^a, Z^c) at the end of the
/// standard teleportation protocol are replaced by their coherent
/// equivalents (CNOT from A to B, CZ from C to B) via the principle of
/// deferred measurement. The measurements on the C and A wires shown in
/// the diagram are therefore omitted — they are only needed to extract the
/// classical bits used for the corrections, which are no longer required.
///
/// To verify that the state |psi> has been teleported onto qubit B, we
/// apply the adjoint of the state preparation to B and measure it. If
/// teleportation succeeded, B should be returned to |0> and the
/// measurement result should always be `Zero`.
operation Main() : Result {
    use c = Qubit();   // Holds |psi>, the state to teleport.
    use a = Qubit();   // Alice's half of the Bell pair |Phi+>.
    use b = Qubit();   // Bob's half of the Bell pair |Phi+>.

    // Prepare an arbitrary, non-trivial state |psi> on qubit c.
    PreparePsi(c);

    // Prepare the shared Bell pair |Phi+> = (|00> + |11>) / sqrt(2)
    // across qubits a and b.
    H(a);
    CNOT(a, b);

    // Standard teleportation entangling operations on the sender side.
    CNOT(c, a);
    H(c);

    // Deferred-measurement equivalents of the classical corrections:
    //   - CNOT(a, b) replaces "if measure(a) == One then X(b)"
    //   - CZ(c, b)   replaces "if measure(c) == One then Z(b)"
    CNOT(a, b);
    CZ(c, b);

    // At this point qubit b holds the teleported state |psi>.
    // Undo the state preparation; b should return to |0>.
    Adjoint PreparePsi(b);

    // Reset the auxiliary qubits so the allocation contract is satisfied.
    Reset(c);
    Reset(a);

    return M(b);
}

/// Prepares a non-trivial single-qubit state |psi> on the given qubit,
/// assumed to start in |0>. Defined as an `is Adj` operation so its
/// inverse can be applied for verification.
operation PreparePsi(q : Qubit) : Unit is Adj {
    Rx(1.1, q);
    Ry(0.7, q);
    Rz(0.3, q);
}
