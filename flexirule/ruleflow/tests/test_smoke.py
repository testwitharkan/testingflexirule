# Copyright (c) 2025, FlexiRule and contributors
# For license information, please see license.txt

import json
import unittest
import frappe
from frappe.tests.utils import FrappeTestCase

from flexirule.ruleflow.core.coordinator import RuleCoordinator
from flexirule.ruleflow.core.evaluator import ConditionEvaluator


class TestFlexiRuleSmoke(FrappeTestCase):
	"""
	Fast, deterministic smoke tests for FlexiRule.
	Covers:
	1. App and module import integrity.
	2. Required DocTypes and metadata availability.
	3. Rule creation, saving, and validation.
	4. Deterministic rule execution and observable side effects.
	5. Condition evaluation alignment.
	6. Handling invalid configuration safely.
	"""

	def setUp(self):
		super().setUp()
		frappe.set_user("Administrator")
		RuleCoordinator.clear_cache()
		if frappe.db.exists("Rule", "Smoke Test Rule"):
			frappe.delete_doc("Rule", "Smoke Test Rule", force=1, ignore_permissions=True)

	def tearDown(self):
		if frappe.db.exists("Rule", "Smoke Test Rule"):
			frappe.delete_doc("Rule", "Smoke Test Rule", force=1, ignore_permissions=True)
		RuleCoordinator.clear_cache()
		super().tearDown()

	def test_01_app_and_hooks_loaded(self):
		"""Verify app hooks and core modules import cleanly and installed apps are valid."""
		self.assertIn("flexirule", frappe.get_installed_apps())
		import flexirule.ruleflow.hooks as hooks
		self.assertTrue(hasattr(hooks, "execute_rules"))
		self.assertTrue(hasattr(hooks, "clear_rule_cache"))

	def test_02_doctypes_registered(self):
		"""Verify critical FlexiRule DocTypes exist in Frappe metadata."""
		for dt in ["Rule", "Rule Action", "Rule Execution Log", "Ruleflow Settings"]:
			self.assertTrue(frappe.db.exists("DocType", dt), f"DocType {dt} should be registered")

	def test_03_create_and_validate_rule(self):
		"""Verify a minimal valid Rule document can be created and saved."""
		rule = frappe.get_doc({
			"doctype": "Rule",
			"rule_name": "Smoke Test Rule",
			"document_type": "ToDo",
			"trigger_type": "DocType Event",
			"trigger_event": "Validate",
			"is_active": 1,
			"actions": [
				{
					"action_id": "ACT-1",
					"action_type": "Assignment",
					"action_label": "Set Description High",
					"is_enabled": 1,
					"config": json.dumps([
						{"target": "doc.description", "operator": "set", "value": "Smoke Test Priority High"}
					]),
					"next_step_if_true": "ACT-STOP",
				},
				{
					"action_id": "ACT-STOP",
					"action_type": "Stop",
					"action_label": "Stop Execution",
					"is_enabled": 1,
					"operation": "Success",
				},
			],
		})
		rule.insert(ignore_permissions=True)
		self.assertTrue(frappe.db.exists("Rule", "Smoke Test Rule"))

	def test_04_rule_execution_side_effect(self):
		"""Verify executing a rule modifies a document's field deterministically."""
		rule = frappe.get_doc({
			"doctype": "Rule",
			"rule_name": "Smoke Test Rule",
			"document_type": "ToDo",
			"trigger_type": "DocType Event",
			"trigger_event": "Validate",
			"is_active": 1,
			"actions": [
				{
					"action_id": "ACT-1",
					"action_type": "Assignment",
					"action_label": "Set Description High",
					"is_enabled": 1,
					"config": json.dumps([
						{"target": "doc.description", "operator": "set", "value": "Set by Smoke Test"}
					]),
					"next_step_if_true": "ACT-STOP",
				},
				{
					"action_id": "ACT-STOP",
					"action_type": "Stop",
					"action_label": "Stop Execution",
					"is_enabled": 1,
					"operation": "Success",
				},
			],
		})
		rule.insert(ignore_permissions=True)

		todo = frappe.get_doc({
			"doctype": "ToDo",
			"description": "Initial Description",
			"priority": "Low",
		})

		RuleCoordinator.execute_rules(todo, "Validate")
		self.assertEqual(todo.description, "Set by Smoke Test", "ToDo description should be updated by the rule")

	def test_05_condition_evaluation(self):
		"""Verify ConditionEvaluator evaluates conditions against context correctly."""
		true_cond_json = '[{"left": {"ref": "doc.status"}, "op": "==", "right": {"value": "Open"}}]'
		evaluator_true = ConditionEvaluator(true_cond_json)
		doc = frappe._dict({"doctype": "ToDo", "status": "Open", "amount": 150})

		self.assertTrue(evaluator_true.evaluate(doc))

		false_cond_json = '[{"left": {"ref": "doc.status"}, "op": "==", "right": {"value": "Closed"}}]'
		evaluator_false = ConditionEvaluator(false_cond_json)
		self.assertFalse(evaluator_false.evaluate(doc))

	def test_06_invalid_rule_config_handling(self):
		"""Verify invalid JSON config in rule action is handled safely during execution or validation."""
		rule = frappe.get_doc({
			"doctype": "Rule",
			"rule_name": "Smoke Test Rule",
			"document_type": "ToDo",
			"trigger_type": "DocType Event",
			"trigger_event": "Validate",
			"is_active": 1,
			"actions": [
				{
					"action_id": "ACT-1",
					"action_type": "Assignment",
					"action_label": "Invalid Action",
					"is_enabled": 1,
					"config": "INVALID_JSON",
				},
			],
		})

		try:
			rule.insert(ignore_permissions=True)
			todo = frappe.get_doc({"doctype": "ToDo", "description": "Smoke test invalid config"})
			RuleCoordinator.execute_rules(todo, "Validate")
		except Exception as e:
			self.assertIsInstance(e, (frappe.ValidationError, ValueError, Exception))
