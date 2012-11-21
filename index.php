<?php

// debug
error_reporting( E_ALL );
ini_set( 'display_errors', true );

/*
 * includes
 */

require_once( "./Config.php" );    // `Config` static class
require_once( "./Tangerine.php" ); // main tangerine interactions
require_once( "./Group.php" );     // Tangerine Group handling
require_once( "./User.php" );      // Tangerine User handling
require_once( "./Attempt.php" );   // success error reporting
require_once( "./Helpers.php" );   // useful methods

/*
 * "main"
 */

$action = Helpers::require_variable('action', 'an action');

/*
 * note: What follows is not very DRY code. Some simple refactoringinto the Tangerine class would work.
 * Left to implement: delete_group, delete_user
 */

if ( $action )
{

	// Create new group
	if ( $action == "new_user" )
	{

		$user_name  = Helpers::require_variable('auth_u', 'a username');
		$user_pass  = Helpers::require_variable('auth_p', 'user authentication');

		try
		{
			$user = new User(array(
				"name" => $user_name,
				"pass" => $user_pass
			));

			$user->save();

			$attempt = new Attempt( 'success', 'User created.' );


		} catch ( Exception $e )
		{
			$attempt = new Attempt( 'error', $e->getMessage() );
		}

		// END of new_user

	}
	else if ( $action == "new_group" )
	{

		/*
		 * Make a new group
		 */

		$group_name = Helpers::require_variable('group', 'a group name.');
		$user_name  = Helpers::require_variable('auth_u', 'a username');
		$user_pass  = Helpers::require_variable('auth_p', 'user authentication');

		try
		{

			$user = new User(array(
				"name" => $user_name,
				"pass" => $user_pass
			));

			// Verify user exists
			if ( ! $user->authenticate() ) throw new Exception( "Must be valid user." );

			$group = new Group( array(
				"name" => $group_name
			));

			$group->create();
			$group->upgrade();
			$group->add_admin( $user );
			$group->add_reader( $user );

			$attempt = new Attempt( 'success', 'Group created.' );

		} catch ( Exception $e )
		{
			$attempt = new Attempt( 'error', $e->getMessage() );
		}

    // END of new_group

	} else if ( $action == "add_admin" )
	{

		/*
		 * Add an admin to a group
		 */

		$group_name = Helpers::require_variable('group', 'a group name');

		$target_user_name = Helpers::require_variable('user', 'a user to add');

		$user_name = Helpers::require_variable('auth_u', 'a username');
		$user_pass = Helpers::require_variable('auth_p', 'user authentication');

		try
		{

			// Authenticate user making request
			$admin_user = new User(array(
				"name" => $user_name,
				"pass" => $user_pass
			));

			if ( ! $admin_user->authenticate() ) throw new Exception( "Authentication failed." );

			$user = new User(array(
				"name" => $target_user_name,
				"admin" => true
			));

			// Verify user exists
			$user->read();

			if ( ! $user->is_authenticated() ) throw new Exception( $user->get_name() . " is not a valid user." );

			$group = new Group( array( "name" => $group_name ));

			// Assert group's existence
			$group->read();

			if ( ! $group->is_admin( $admin_user ) ) throw new Exception( "You must be an admin to add admin members." );

			$group->add_admin( $user );

			$attempt = new Attempt( 'success', $user->get_name() . ' added to ' . $group->get_name() . ' as admin.' );

		} catch ( Exception $e )
		{
			$attempt = new Attempt( 'error', $e->getMessage() );
		}


    // END of add_admin
	} else if ( $action == "remove_admin" )
	{

		/*
		 * Remove an admin from a group
		 */

		$group_name = Helpers::require_variable('group', 'a group name');

		$target_user_name = Helpers::require_variable('user', 'a user to remove');

		$user_name = Helpers::require_variable('auth_u', 'a username');
		$user_pass = Helpers::require_variable('auth_p', 'user authentication');

		try
		{

			// Authenticate user making request
			$admin_user = new User( array(
				"name" => $user_name,
				"pass" => $user_pass
			));

			if ( ! $admin_user->authenticate() ) throw new Exception( "Authentication failed." );

			$user = new User(array(
				"name" => $target_user_name,
				"admin" => true
			));

			// Verify user exists
			$user->read();

			if ( ! $user->is_authenticated() ) throw new Exception( $user->get_name() . " is not a valid user." );

			$group = new Group( array( "name" => $group_name ) );

			// Assert group's existence
			$group->read();

			if ( ! $group->is_admin( $admin_user ) ) throw new Exception( "You must be an admin to remove admin members." );

			$group->remove_admin( $user );

			$attempt = new Attempt( 'success', 'Removed admin ' . $user->get_name() . ' from ' . $group->get_name() . '.' );

		} catch ( Exception $e )
		{
			$attempt = new Attempt( 'error', $e->getMessage() );
		}

	// END of remove_admin

	} else if ( $action == "add_reader" )
	{

		/*
		 * Add a reader to a group
		 */

		$group_name = Helpers::require_variable('group', 'a group name');

		$target_user_name = Helpers::require_variable('user', 'a user to add');

		$user_name = Helpers::require_variable('auth_u', 'a username');
		$user_pass = Helpers::require_variable('auth_p', 'user authentication');

		try
		{

			// Authenticate user making request
			$admin_user = new User(array(
				"name" => $user_name,
				"pass" => $user_pass
			));

			if ( ! $admin_user->authenticate() ) throw new Exception( "Authentication failed." );

			$user = new User(array(
				"name" => $target_user_name,
				"admin" => true
			));

			// Verify user exists
			$user->read();

			if ( ! $user->is_authenticated() ) throw new Exception( $user->get_name() . " is not a valid user." );

			$group = new Group( array( "name" => $group_name ));

			// Assert group's existence
			$group->read();

			if ( ! $group->is_admin( $admin_user ) ) throw new Exception( "You must be an admin to add readers." );

			$group->add_reader( $user );

			$attempt = new Attempt( 'success', $user->get_name() . ' added to ' . $group->get_name() . ' as reader.' );

		} catch ( Exception $e )
		{
			$attempt = new Attempt( 'error', $e->getMessage() );
		}

    // END of add_reader

	}else if ( $action == "remove_reader" )
	{

		/*
		 * Remove a reader from a group.
		 */

		$group_name = Helpers::require_variable('group', 'a group name');

		$target_user_name = Helpers::require_variable('user', 'a user to remove');

		$user_name = Helpers::require_variable('auth_u', 'a username');
		$user_pass = Helpers::require_variable('auth_p', 'user authentication');

		try
		{

			// Authenticate user making request
			$admin_user = new User( array(
				"name" => $user_name,
				"pass" => $user_pass
			));

			if ( ! $admin_user->authenticate() ) throw new Exception( "Authentication failed." );

			$user = new User(array(
				"name" => $target_user_name,
				"admin" => true
			));

			// Verify user exists
			$user->read();

			if ( ! $user->is_authenticated() ) throw new Exception( $user->get_name() . " is not a valid user." );

			$group = new Group( array( "name" => $group_name ) );

			// Assert group's existence
			$group->read();

			if ( ! $group->is_admin( $admin_user ) ) throw new Exception( "You must be an admin to remove readers." );

			$group->remove_reader( $user );

			$attempt = new Attempt( 'success', 'Removed admin ' . $user->get_name() . ' from ' . $group->get_name() . '.' );

		} catch ( Exception $e )
		{
			$attempt = new Attempt( 'error', $e->getMessage() );
		}

	}

}

Helpers::respond_json( $attempt );


?>