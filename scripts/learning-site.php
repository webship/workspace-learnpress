<?php
/**
 * The courses of the test site: the accounts' places and the test content.
 *
 * Run inside the site with WP-CLI, once the plugin is active:
 *
 *   wp eval-file learning-site.php              the courses, their lessons and quiz, and the student's enrolment
 *                                               (what is there already is kept)
 *   wp eval-file learning-site.php content      the same
 *   wp eval-file learning-site.php reset        put the courses back as the build left them: what a stopped run left
 *                                               behind goes (the students' orders, progress, quiz attempts and their
 *                                               history, "Webship test …" courses), the student's enrolment comes back
 *   wp eval-file learning-site.php status       say what the courses hold
 *   wp eval-file learning-site.php counts       the counts a test run must leave as it found them (CI compares them)
 *   wp eval-file learning-site.php orphans      remove what the plugin's tables keep of deleted accounts and courses
 *
 * Everything is made with the plugin's own models (CourseService, CoursePostModel::add_section,
 * CourseSectionModel::add_items, LessonPostModel, QuizPostModel, QuestionPostModel, UserCourseModel), so the counts and
 * the curriculum are the ones the plugin keeps. No account is created here: the build creates them.
 */

use LearnPress\Models\CoursePostModel;
use LearnPress\Models\LessonPostModel;
use LearnPress\Models\QuizPostModel;
use LearnPress\Models\Question\QuestionPostModel;
use LearnPress\Models\UserItems\UserCourseModel;
use LearnPress\Models\UserItems\UserItemModel;
use LearnPress\Services\CourseService;

$webship_mode = isset( $args[0] ) ? $args[0] : 'all';

function webship_user_id( $login ) {
	$user = get_user_by( 'login', $login );
	return $user ? (int) $user->ID : 0;
}

/** The courses of the test content: each with its sections, and each section with its lessons or quiz. */
function webship_courses() {
	return array(
		'webship-testing-basics' => array(
			'title'    => 'Webship Testing Basics',
			'content'  => 'Learn how a feature, its scenarios and their steps describe what a site does.',
			'sections' => array(
				'Getting started'           => array(
					array( 'lesson', 'What a scenario is', 'A scenario is one example of what the site does, written as steps a person can read.' ),
					array( 'lesson', 'Steps and features', 'A feature groups the scenarios of one part of the site. Each step is a sentence a definition matches.' ),
				),
				'Check what you learned'    => array(
					array( 'quiz', 'Basics quiz', 'Three questions on features, scenarios and steps.' ),
				),
			),
		),
		'webship-advanced-testing' => array(
			'title'    => 'Webship Advanced Testing',
			'content'  => 'Tags, hooks and the reports a run writes.',
			'sections' => array(
				'Running a suite' => array(
					array( 'lesson', 'Tags and hooks', 'A tag picks the scenarios a run takes; a hook runs before or after each of them.' ),
				),
			),
		),
	);
}

/** The questions of the quiz: type, title, answers (title => correct). */
function webship_questions() {
	return array(
		array( 'true_or_false', 'A feature holds scenarios.', array( 'True' => true, 'False' => false ) ),
		array( 'single_choice', 'Which keyword sets the scene of a scenario?', array( 'Given' => true, 'When' => false, 'Then' => false ) ),
		array( 'multi_choice', 'Which words start a step?', array( 'Given' => true, 'When' => true, 'Then' => true, 'Before' => false ) ),
	);
}

function webship_find_post( $title, $type ) {
	$posts = get_posts( array( 'post_type' => $type, 'title' => $title, 'post_status' => 'any', 'numberposts' => 1, 'fields' => 'ids' ) );
	return $posts ? (int) $posts[0] : 0;
}

function webship_add_question( $quiz_id, $type, $title, $answers ) {
	global $wpdb;
	$question_id = wp_insert_post( array(
		'post_title'  => $title,
		'post_type'   => LP_QUESTION_CPT,
		'post_status' => 'publish',
		'post_author' => webship_user_id( 'instructor' ),
	) );
	update_post_meta( $question_id, '_lp_type', $type );
	$wpdb->insert( $wpdb->learnpress_quiz_questions, array( 'quiz_id' => $quiz_id, 'question_id' => $question_id ), array( '%d', '%d' ) );
	$rows  = array();
	$order = 0;
	foreach ( $answers as $answer => $correct ) {
		$order++;
		$row = array(
			'title'   => $answer,
			'value'   => sanitize_title( $answer ) . '-' . $question_id,
			'is_true' => $correct ? 'yes' : 'no',
		);
		$wpdb->insert( $wpdb->learnpress_question_answers, array_merge( array( 'question_id' => $question_id, 'order' => $order ), $row ), array( '%d', '%d', '%s', '%s', '%s' ) );
		$rows[] = $row;
	}
	$model = QuestionPostModel::find( $question_id, true );
	if ( $model ) {
		$model->save_answers_config( $rows );
	}
	return $question_id;
}

function webship_set_courses() {
	$instructor = webship_user_id( 'instructor' );
	wp_set_current_user( $instructor );
	foreach ( webship_courses() as $slug => $course ) {
		if ( webship_find_post( $course['title'], LP_COURSE_CPT ) ) {
			echo "  course {$course['title']}: there already\n";
			continue;
		}
		$model = CourseService::instance()->create_info_main( array(
			'post_title'   => $course['title'],
			'post_name'    => $slug,
			'post_type'    => LP_COURSE_CPT,
			'post_status'  => 'publish',
			'post_content' => $course['content'],
			'post_author'  => $instructor,
			'meta_input'   => array(
				CoursePostModel::META_KEY_DURATION => '2 week',
				CoursePostModel::META_KEY_LEVEL    => 'all',
			),
		) );
		foreach ( $course['sections'] as $section_name => $items ) {
			$section = $model->add_section( array( 'section_name' => $section_name ) );
			foreach ( $items as $item ) {
				list( $kind, $title, $content ) = $item;
				if ( 'lesson' === $kind ) {
					$post               = new LessonPostModel();
					$post->post_type    = LP_LESSON_CPT;
				} else {
					$post               = new QuizPostModel();
					$post->post_type    = LP_QUIZ_CPT;
				}
				$post->post_title   = $title;
				$post->post_status  = 'publish';
				$post->post_author  = $instructor;
				$post->post_content = $content;
				$post->save();
				$section->add_items( array( 'items' => array( array( 'id' => $post->get_id(), 'type' => $post->post_type ) ) ) );
				if ( 'quiz' === $kind ) {
					update_post_meta( $post->get_id(), QuizPostModel::META_KEY_PASSING_GRADE, 60 );
					update_post_meta( $post->get_id(), QuizPostModel::META_KEY_RETAKE_COUNT, 2 );
					update_post_meta( $post->get_id(), QuizPostModel::META_KEY_REVIEW, 'yes' );
					update_post_meta( $post->get_id(), QuizPostModel::META_KEY_SHOW_CORRECT_REVIEW, 'yes' );
					foreach ( webship_questions() as $question ) {
						webship_add_question( $post->get_id(), $question[0], $question[1], $question[2] );
					}
				}
			}
		}
		echo "  course {$course['title']}\n";
	}
	wp_set_current_user( 0 );
}

function webship_set_enrolment() {
	$student   = webship_user_id( 'student' );
	$course_id = webship_find_post( 'Webship Testing Basics', LP_COURSE_CPT );
	if ( ! $student || ! $course_id ) {
		return;
	}
	$existing = UserCourseModel::find( $student, $course_id, false );
	if ( $existing instanceof UserCourseModel ) {
		echo "  student: enrolled already\n";
		return;
	}
	$enrolment             = new UserCourseModel();
	$enrolment->user_id    = $student;
	$enrolment->item_id    = $course_id;
	$enrolment->item_type  = LP_COURSE_CPT;
	$enrolment->ref_type   = '';
	$enrolment->status     = UserItemModel::STATUS_ENROLLED;
	$enrolment->graduation = UserItemModel::GRADUATION_IN_PROGRESS;
	$enrolment->start_time = gmdate( 'Y-m-d H:i:s' );
	$enrolment->save();
	echo "  student: enrolled in Webship Testing Basics\n";
}

function webship_status() {
	foreach ( webship_courses() as $slug => $course ) {
		$course_id = webship_find_post( $course['title'], LP_COURSE_CPT );
		echo "{$course['title']}: " . ( $course_id ? get_permalink( $course_id ) : 'not on the site' ) . "\n";
	}
	global $wpdb;
	foreach ( array( 'instructor', 'student', 'student2' ) as $login ) {
		$user_id = webship_user_id( $login );
		$items   = $user_id ? $wpdb->get_results( $wpdb->prepare( "SELECT item_type, status, graduation FROM {$wpdb->learnpress_user_items} WHERE user_id = %d ORDER BY user_item_id", $user_id ) ) : array();
		echo "{$login}: " . ( $user_id ? ( $items ? implode( ', ', array_map( function ( $i ) { return "{$i->item_type} {$i->status}" . ( $i->graduation ? " ({$i->graduation})" : '' ); }, $items ) ) : 'nothing' ) : 'not on the site' ) . "\n";
	}
}

/** The accounts of the suite that learn: their courses, progress and orders are what a run changes. */
function webship_learners() {
	return array( 'student', 'student2' );
}

/** The orders of an account (any status, trash included). */
function webship_orders_of( $user_id ) {
	global $wpdb;
	return array_map( 'intval', $wpdb->get_col( $wpdb->prepare(
		"SELECT p.ID FROM {$wpdb->posts} p JOIN {$wpdb->postmeta} m ON m.post_id = p.ID AND m.meta_key = '_user_id' WHERE p.post_type = %s AND m.meta_value = %d",
		LP_ORDER_CPT,
		$user_id
	) ) );
}

function webship_delete_order( $order_id ) {
	global $wpdb;
	$items = $wpdb->get_col( $wpdb->prepare( "SELECT order_item_id FROM {$wpdb->learnpress_order_items} WHERE order_id = %d", $order_id ) );
	foreach ( $items as $item ) {
		$wpdb->delete( $wpdb->learnpress_order_itemmeta, array( 'learnpress_order_item_id' => $item ), array( '%d' ) );
	}
	$wpdb->delete( $wpdb->learnpress_order_items, array( 'order_id' => $order_id ), array( '%d' ) );
	wp_delete_post( $order_id, true );
}

/** A course, its sections, and the lessons, quizzes and questions only it uses, deleted. */
function webship_delete_course( $course_id ) {
	global $wpdb;
	$sections = $wpdb->get_col( $wpdb->prepare( "SELECT section_id FROM {$wpdb->learnpress_sections} WHERE section_course_id = %d", $course_id ) );
	foreach ( $sections as $section_id ) {
		$items = $wpdb->get_col( $wpdb->prepare( "SELECT item_id FROM {$wpdb->learnpress_section_items} WHERE section_id = %d", $section_id ) );
		foreach ( $items as $item_id ) {
			webship_delete_item( (int) $item_id );
		}
		$wpdb->delete( $wpdb->learnpress_section_items, array( 'section_id' => $section_id ), array( '%d' ) );
		$wpdb->delete( $wpdb->learnpress_sections, array( 'section_id' => $section_id ), array( '%d' ) );
	}
	$wpdb->delete( $wpdb->learnpress_user_items, array( 'item_id' => $course_id ), array( '%d' ) );
	$wpdb->delete( $wpdb->learnpress_user_items, array( 'ref_id' => $course_id ), array( '%d' ) );
	wp_delete_post( $course_id, true );
	$courses = $wpdb->prefix . 'learnpress_courses';
	if ( $wpdb->get_var( $wpdb->prepare( 'SHOW TABLES LIKE %s', $courses ) ) === $courses ) {
		$wpdb->delete( $courses, array( 'ID' => $course_id ), array( '%d' ) );
	}
}

/** A lesson or a quiz (with its questions and their answers), deleted. */
function webship_delete_item( $item_id ) {
	global $wpdb;
	if ( LP_QUIZ_CPT === get_post_type( $item_id ) ) {
		$questions = $wpdb->get_col( $wpdb->prepare( "SELECT question_id FROM {$wpdb->learnpress_quiz_questions} WHERE quiz_id = %d", $item_id ) );
		foreach ( $questions as $question_id ) {
			webship_delete_question( (int) $question_id );
		}
		$wpdb->delete( $wpdb->learnpress_quiz_questions, array( 'quiz_id' => $item_id ), array( '%d' ) );
	}
	$wpdb->delete( $wpdb->learnpress_section_items, array( 'item_id' => $item_id ), array( '%d' ) );
	wp_delete_post( $item_id, true );
}

function webship_delete_question( $question_id ) {
	global $wpdb;
	$wpdb->delete( $wpdb->learnpress_question_answers, array( 'question_id' => $question_id ), array( '%d' ) );
	$config = $wpdb->prefix . 'learnpress_question_answer_config';
	if ( $wpdb->get_var( $wpdb->prepare( 'SHOW TABLES LIKE %s', $config ) ) === $config ) {
		$wpdb->delete( $config, array( 'question_id' => $question_id ), array( '%d' ) );
	}
	$wpdb->delete( $wpdb->learnpress_quiz_questions, array( 'question_id' => $question_id ), array( '%d' ) );
	wp_delete_post( $question_id, true );
}

/**
 * What a stopped run left behind: the learners' orders and their enrolments and progress (the student's enrolment of
 * the build comes back fresh), the courses, lessons, quizzes and questions of the suite ("Webship test …"), and the
 * status of the build's courses.
 */
function webship_reset() {
	global $wpdb;
	foreach ( webship_learners() as $login ) {
		$user_id = webship_user_id( $login );
		if ( ! $user_id ) {
			continue;
		}
		foreach ( webship_orders_of( $user_id ) as $order_id ) {
			webship_delete_order( $order_id );
			echo "  {$login}: order {$order_id} removed\n";
		}
		$courses = $wpdb->get_col( $wpdb->prepare( "SELECT DISTINCT item_id FROM {$wpdb->learnpress_user_items} WHERE user_id = %d AND item_type = %s", $user_id, LP_COURSE_CPT ) );
		foreach ( $courses as $course_id ) {
			LP_User_Items_DB::getInstance()->delete_user_items_old( $user_id, (int) $course_id );
		}
		$wpdb->delete( $wpdb->learnpress_user_items, array( 'user_id' => $user_id ), array( '%d' ) );
		// The plugin's history of the account's enrolments and attempts: a row a user item, kept by its own tools when
		// the user item goes.
		$wpdb->delete( $wpdb->learnpress_user_item_results, array( 'user_id' => $user_id ), array( '%d' ) );
	}
	foreach ( array( LP_COURSE_CPT, LP_LESSON_CPT, LP_QUIZ_CPT, LP_QUESTION_CPT ) as $type ) {
		// "Webship test " exactly, case and space included: LIKE alone ignores case, and "Webship Testing Basics" is the
		// build's own course.
		$posts = $wpdb->get_col( $wpdb->prepare( "SELECT ID FROM {$wpdb->posts} WHERE post_type = %s AND post_title LIKE BINARY %s", $type, 'Webship test %' ) );
		foreach ( $posts as $post_id ) {
			if ( ! get_post( $post_id ) ) {
				continue;
			}
			if ( LP_COURSE_CPT === $type ) {
				webship_delete_course( (int) $post_id );
			} elseif ( LP_QUESTION_CPT === $type ) {
				webship_delete_question( (int) $post_id );
			} else {
				webship_delete_item( (int) $post_id );
			}
			echo "  {$type} {$post_id} removed\n";
		}
	}
	foreach ( webship_courses() as $slug => $course ) {
		$course_id = webship_find_post( $course['title'], LP_COURSE_CPT );
		if ( $course_id && 'publish' !== get_post_status( $course_id ) ) {
			wp_update_post( array( 'ID' => $course_id, 'post_status' => 'publish' ) );
			echo "  course {$course['title']}: published again\n";
		}
	}
	webship_set_enrolment();
}

/**
 * What a run must leave as it found it, one count a line, the same on every run of the same site: the courses by
 * status, the lessons, quizzes, questions, sections and their items, the orders by status, the plugin's history rows
 * (one an enrolment or an attempt), and each account's enrolments, progress rows and quiz attempts by status, its
 * orders and its history rows. CI compares it before and after the suite.
 */
function webship_counts() {
	global $wpdb;
	$lines = array();
	foreach ( array( LP_COURSE_CPT, LP_LESSON_CPT, LP_QUIZ_CPT, LP_QUESTION_CPT, LP_ORDER_CPT ) as $type ) {
		$rows = $wpdb->get_results( $wpdb->prepare( "SELECT post_status, COUNT(*) AS n FROM {$wpdb->posts} WHERE post_type = %s GROUP BY post_status ORDER BY post_status", $type ) );
		$lines[] = "{$type}: " . ( $rows ? implode( ', ', array_map( function ( $r ) { return "{$r->post_status} {$r->n}"; }, $rows ) ) : 'none' );
	}
	$lines[] = 'sections: ' . (int) $wpdb->get_var( "SELECT COUNT(*) FROM {$wpdb->learnpress_sections}" );
	$lines[] = 'section items: ' . (int) $wpdb->get_var( "SELECT COUNT(*) FROM {$wpdb->learnpress_section_items}" );
	$lines[] = 'quiz questions: ' . (int) $wpdb->get_var( "SELECT COUNT(*) FROM {$wpdb->learnpress_quiz_questions}" );
	$lines[] = 'history rows: ' . (int) $wpdb->get_var( "SELECT COUNT(*) FROM {$wpdb->learnpress_user_item_results}" );
	foreach ( array( 'administrator', 'instructor', 'student', 'student2' ) as $login ) {
		$user_id = webship_user_id( $login );
		if ( ! $user_id ) {
			$lines[] = "{$login}: not on the site";
			continue;
		}
		$rows = $wpdb->get_results( $wpdb->prepare( "SELECT item_type, status, graduation, COUNT(*) AS n FROM {$wpdb->learnpress_user_items} WHERE user_id = %d GROUP BY item_type, status, graduation ORDER BY item_type, status, graduation", $user_id ) );
		$lines[] = "{$login} items: " . ( $rows ? implode( ', ', array_map( function ( $r ) { return trim( "{$r->item_type} {$r->status} {$r->graduation}" ) . " {$r->n}"; }, $rows ) ) : 'none' );
		$lines[] = "{$login} orders: " . count( webship_orders_of( $user_id ) );
		$rows    = $wpdb->get_results( $wpdb->prepare( "SELECT item_type, COUNT(*) AS n FROM {$wpdb->learnpress_user_item_results} WHERE user_id = %d GROUP BY item_type ORDER BY item_type", $user_id ) );
		$lines[] = "{$login} history: " . ( $rows ? implode( ', ', array_map( function ( $r ) { return "{$r->item_type} {$r->n}"; }, $rows ) ) : 'none' );
	}
	foreach ( webship_courses() as $slug => $course ) {
		$course_id = webship_find_post( $course['title'], LP_COURSE_CPT );
		$lines[] = "{$course['title']}: " . ( $course_id ? get_post_status( $course_id ) . ', ' . (int) $wpdb->get_var( $wpdb->prepare( "SELECT COUNT(DISTINCT user_id) FROM {$wpdb->learnpress_user_items} WHERE item_id = %d AND item_type = %s", $course_id, LP_COURSE_CPT ) ) . ' learners' : 'not on the site' );
	}
	echo implode( "\n", $lines ) . "\n";
}

/**
 * What the plugin keeps of what WordPress deleted from outside the plugin's screens. An account deleted with WP-CLI
 * takes its courses along, and the plugin keeps the account's enrolments, progress and history, its orders, the
 * sections of its courses and their items, and its lessons, quizzes and questions (types WordPress does not delete
 * with an author). The Workspace's cancel of the test users runs this once the accounts are gone.
 */
function webship_orphans() {
	global $wpdb;
	$gone = array();
	$orders = $wpdb->get_col( $wpdb->prepare(
		"SELECT p.ID FROM {$wpdb->posts} p JOIN {$wpdb->postmeta} m ON m.post_id = p.ID AND m.meta_key = '_user_id' LEFT JOIN {$wpdb->users} u ON u.ID = m.meta_value WHERE p.post_type = %s AND m.meta_value > 0 AND u.ID IS NULL",
		LP_ORDER_CPT
	) );
	foreach ( $orders as $order_id ) {
		webship_delete_order( (int) $order_id );
	}
	$gone['orders'] = count( $orders );
	$items  = $wpdb->learnpress_user_items;
	$meta   = $wpdb->learnpress_user_itemmeta;
	$result = $wpdb->learnpress_user_item_results;
	$gone['enrolments and progress'] = (int) $wpdb->query( "DELETE ui FROM {$items} ui LEFT JOIN {$wpdb->users} u ON u.ID = ui.user_id WHERE ui.user_id > 0 AND u.ID IS NULL" )
		+ (int) $wpdb->query( "DELETE ui FROM {$items} ui LEFT JOIN {$wpdb->posts} p ON p.ID = ui.item_id WHERE p.ID IS NULL" );
	$wpdb->query( "DELETE m FROM {$meta} m LEFT JOIN {$items} ui ON ui.user_item_id = m.learnpress_user_item_id WHERE ui.user_item_id IS NULL" );
	$gone['history rows'] = (int) $wpdb->query( "DELETE r FROM {$result} r LEFT JOIN {$wpdb->users} u ON u.ID = r.user_id WHERE r.user_id > 0 AND u.ID IS NULL" );
	$sections = $wpdb->learnpress_sections;
	$gone['sections'] = (int) $wpdb->query( "DELETE s FROM {$sections} s LEFT JOIN {$wpdb->posts} p ON p.ID = s.section_course_id WHERE p.ID IS NULL" );
	$gone['section items'] = (int) $wpdb->query( "DELETE si FROM {$wpdb->learnpress_section_items} si LEFT JOIN {$sections} s ON s.section_id = si.section_id LEFT JOIN {$wpdb->posts} p ON p.ID = si.item_id WHERE s.section_id IS NULL OR p.ID IS NULL" );
	// WordPress deletes an account's courses with it, but not its lessons, quizzes and questions (their types have no
	// author support): those of an account that is gone go when no course uses them any more.
	$items = $wpdb->get_col( $wpdb->prepare(
		"SELECT p.ID FROM {$wpdb->posts} p LEFT JOIN {$wpdb->users} u ON u.ID = p.post_author LEFT JOIN {$wpdb->learnpress_section_items} si ON si.item_id = p.ID WHERE p.post_type IN (%s, %s) AND p.post_author > 0 AND u.ID IS NULL AND si.item_id IS NULL",
		LP_LESSON_CPT,
		LP_QUIZ_CPT
	) );
	foreach ( $items as $item_id ) {
		webship_delete_item( (int) $item_id );
	}
	$gone['lessons and quizzes'] = count( $items );
	$questions = $wpdb->get_col( $wpdb->prepare(
		"SELECT p.ID FROM {$wpdb->posts} p LEFT JOIN {$wpdb->users} u ON u.ID = p.post_author LEFT JOIN {$wpdb->learnpress_quiz_questions} qq ON qq.question_id = p.ID WHERE p.post_type = %s AND p.post_author > 0 AND u.ID IS NULL AND qq.question_id IS NULL",
		LP_QUESTION_CPT
	) );
	foreach ( $questions as $question_id ) {
		webship_delete_question( (int) $question_id );
	}
	$gone['questions'] = count( $questions );
	$gone['quiz questions'] = (int) $wpdb->query( "DELETE qq FROM {$wpdb->learnpress_quiz_questions} qq LEFT JOIN {$wpdb->posts} q ON q.ID = qq.quiz_id LEFT JOIN {$wpdb->posts} p ON p.ID = qq.question_id WHERE q.ID IS NULL OR p.ID IS NULL" );
	$answers = $wpdb->learnpress_question_answers;
	$wpdb->query( "DELETE am FROM {$wpdb->learnpress_question_answermeta} am LEFT JOIN {$answers} a ON a.question_answer_id = am.learnpress_question_answer_id LEFT JOIN {$wpdb->posts} p ON p.ID = a.question_id WHERE a.question_answer_id IS NULL OR p.ID IS NULL" );
	$gone['answers'] = (int) $wpdb->query( "DELETE a FROM {$answers} a LEFT JOIN {$wpdb->posts} p ON p.ID = a.question_id WHERE p.ID IS NULL" );
	$config = $wpdb->prefix . 'learnpress_question_answer_config';
	if ( $wpdb->get_var( $wpdb->prepare( 'SHOW TABLES LIKE %s', $config ) ) === $config ) {
		$wpdb->query( "DELETE c FROM {$config} c LEFT JOIN {$wpdb->posts} p ON p.ID = c.question_id WHERE p.ID IS NULL" );
	}
	$courses = $wpdb->prefix . 'learnpress_courses';
	if ( $wpdb->get_var( $wpdb->prepare( 'SHOW TABLES LIKE %s', $courses ) ) === $courses ) {
		$wpdb->query( "DELETE c FROM {$courses} c LEFT JOIN {$wpdb->posts} p ON p.ID = c.ID WHERE p.ID IS NULL" );
	}
	$left = array_filter( $gone );
	echo $left ? '  removed what the deleted accounts and courses left: ' . implode( ', ', array_map( function ( $what, $n ) { return "{$n} {$what}"; }, array_keys( $left ), $left ) ) . "\n" : "  nothing left by deleted accounts or courses\n";
}

wp_set_current_user( 1 );

switch ( $webship_mode ) {
	case 'all':
	case 'content':
		webship_set_courses();
		webship_set_enrolment();
		break;
	case 'reset':
		webship_reset();
		break;
	case 'status':
		webship_status();
		break;
	case 'counts':
		webship_counts();
		break;
	case 'orphans':
		webship_orphans();
		break;
	default:
		fwrite( STDERR, "Unknown mode {$webship_mode}: content, reset, status, counts or orphans.\n" );
		exit( 1 );
}
