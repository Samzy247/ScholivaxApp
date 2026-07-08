<?php
defined('BASEPATH') OR exit('No direct script access allowed');

/**
 * POST /api/auth/login
 * Called against a tenant subdomain, e.g. https://greenfield.scholivax.top/api/auth/login
 *
 * body: {
 *   "role":       "admin" | "teacher" | "hrm" | "hostel" | "accountant" |
 *                 "librarian" | "parent" | "student"   (optional — see below),
 *   "identifier": "...",   // email for staff roles, Reg No (roll) for student
 *   "password":   "..."
 * }
 *
 * The app's login screen asks for a role first (Admin/Teacher vs Student),
 * so it should always send "role" — that's what decides whether
 * "identifier" is looked up as an email or as a student Reg No, matching
 * the same distinction the web login screen makes.
 *
 * "email" is still accepted as an alias for "identifier" for backward
 * compatibility. If "role" is omitted, every role is tried in turn, in the
 * exact same order Login_model::loginFunctionForAllUsers() uses on the web
 * (admin -> hrm -> hostel -> accountant -> librarian -> teacher -> parent
 * -> student), so the app never rejects a login the website would accept.
 *
 * Returns a bearer token the app stores and sends as:
 *   Authorization: Bearer <token>
 */
class Auth extends CI_Controller {

    // Every staff-style table, looked up by email — same tables and same
    // order as Login_model::loginFunctionForAllUsers() on the web side.
    // (Previously this only listed 'admin', 'teacher', 'parent', which is
    // why hrm / hostel / accountant / librarian accounts always got
    // "Invalid login details" from the app even with the correct password —
    // those three tables were never queried.)
    private $staff_roles = array('admin', 'hrm', 'hostel', 'accountant', 'librarian', 'teacher', 'parent');

    function __construct() {
        parent::__construct();
        $this->load->database();
        $this->load->helper('api_auth');
    }

    public function login() {
        $role       = strtolower(trim($this->input->post('role')));
        $identifier = trim($this->input->post('identifier'));
        if ($identifier === '') {
            $identifier = trim($this->input->post('email')); // back-compat alias
        }
        $password = trim($this->input->post('password'));

        if (empty($identifier) || empty($password)) {
            api_fail($this, 'Login ID and password are required.', 422);
        }

        $hashed = sha1($password);

        // --- Role explicitly given: look up only in that table ------------
        if ($role === 'student') {
            $row = $this->db->get_where('student', array('roll' => $identifier, 'password' => $hashed))->row();
            if ($row) {
                return $this->_issue($this, 'student', $row->student_id, $row);
            }
            api_fail($this, 'Invalid Reg No or password.', 401);
        }

        if (in_array($role, $this->staff_roles)) {
            $row = $this->db->get_where($role, array('email' => $identifier, 'password' => $hashed))->row();
            if ($row) {
                $id_field = $role . '_id';
                return $this->_issue($this, $role, $row->$id_field, $row);
            }
            api_fail($this, 'Invalid email or password.', 401);
        }

        // --- No role given: fall back to trying everything, same order as
        //     the web login screen ------------------------------------------
        foreach ($this->staff_roles as $r) {
            $row = $this->db->get_where($r, array('email' => $identifier, 'password' => $hashed))->row();
            if ($row) {
                $id_field = $r . '_id';
                return $this->_issue($this, $r, $row->$id_field, $row);
            }
        }

        // Student: try Reg No (roll) first — that's the primary student
        // login method — then email as a fallback for older records.
        $row = $this->db->get_where('student', array('roll' => $identifier, 'password' => $hashed))->row();
        if (!$row) {
            $row = $this->db->get_where('student', array('email' => $identifier, 'password' => $hashed))->row();
        }
        if ($row) {
            return $this->_issue($this, 'student', $row->student_id, $row);
        }

        api_fail($this, 'Invalid login details.', 401);
    }

    private function _issue($CI, $role, $user_id, $row) {
        $token = api_issue_token($CI, $role, $user_id);
        api_ok($CI, array(
            'token'     => $token,
            'user_type' => $role,
            'user_id'   => (int) $user_id,
            'name'      => isset($row->name) ? $row->name : null,
            'email'     => isset($row->email) ? $row->email : null,
            'roll'      => isset($row->roll) ? $row->roll : null,
        ));
    }

    // POST /api/auth/logout — invalidates the current token only.
    public function logout() {
        $auth = api_authenticate($this);
        if (!$auth) {
            api_fail($this, 'Not authenticated.', 401);
        }

        $header = $this->input->get_request_header('Authorization', TRUE);
        $token  = trim(substr($header, 7));
        $this->db->where('token', $token);
        $this->db->delete('api_token');

        api_ok($this, array('message' => 'Logged out.'));
    }
}
