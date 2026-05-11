/// Quantum teleportation implemented WITHOUT mid-circuit measurement or
/// classical feed-forward, so it is friendly to current NISQ hardware that
/// only supports terminal measurements.
///
/// Circuit (matches the attached diagram):
///
///     |psi>_C : ---*---H---M===*---
///                  |           |
///     |Phi+>_A : --X-------M=*=|---
///                            |  |
///     |Phi+>_B : -------------X--Z--->  |psi>_B
///
/// Trick: by the deferred-measurement principle we replace the classically
/// controlled X (on a) and Z (on c) with a quantum-controlled CNOT(a,b) and
/// CZ(c,b). All measurements are then pushed to the very end of the circuit.
///
/// To verify teleportation we apply the adjoint of the state-preparation on
/// the receiver qubit b. If teleportation worked, b returns to |0> and the
/// measurement of b is deterministically Zero.

import Std.Diagnostics.*;
import Std.Math.*;

operation Main() : Result {
    // Prepare an arbitrary single-qubit state |psi> on `c`.
    // Pick something non-trivial (not a computational basis state).
    let theta = 1.2;   // arbitrary angle
    let phi   = 0.7;   // arbitrary phase

    use c = Qubit();
    use a = Qubit();
    use b = Qubit();

    // 1) Prepare |psi> on c.
    PreparePsi(theta, phi, c);

    // 2) Prepare the Bell pair |Phi+>_{A,B} on (a, b).
    H(a);
    CNOT(a, b);

    // 3) Bell-basis "measurement" on (c, a) — but defer the measurement.
    CNOT(c, a);
    H(c);

    // 4) Deferred classical corrections become quantum-controlled gates:
    //    classically:  if M(a)==1: X on b ;  if M(c)==1: Z on b
    //    deferred:     CNOT(a, b)            CZ(c, b)
    CNOT(a, b);
    CZ(c, b);

    // At this point b holds |psi> (up to the entanglement with c, a which
    // would normally be collapsed by the measurements — those measurements
    // can be done at the end and discarded without affecting b's reduced
    // state).

    // 5) Apply Adjoint of the state preparation on b. If teleportation
    //    succeeded, b is now back in |0>.
    Adjoint PreparePsi(theta, phi, b);

    // 6) Measure b — should always be Zero.
    let result = MResetZ(b);

    // Reset the other qubits before release.
    Reset(c);
    Reset(a);

    return result;
}

/// Prepares the state cos(theta/2)|0> + e^{i*phi} sin(theta/2)|1> on `q`.
operation PreparePsi(theta : Double, phi : Double, q : Qubit) : Unit is Adj + Ctl {
    Ry(theta, q);
    Rz(phi, q);
}
